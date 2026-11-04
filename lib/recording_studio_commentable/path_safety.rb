# frozen_string_literal: true

require "cgi"
require "uri"

module RecordingStudioCommentable
  # return_to must stay a relative path; avatars must be http(s) or a relative
  # image URL. Private helpers reject backslash, control chars, encoded CRLF,
  # protocol-relative URLs, and userinfo.
  module PathSafety
    UNSAFE_CHARACTERS = /[\\\x00-\x1F\x7F\u0080-\u009F\u2028\u2029]/
    DECODED_CONTROL_CHARACTERS = /[\x00-\x1F\x7F\u0080-\u009F\u2028\u2029]/
    ALLOWED_AVATAR_SCHEMES = %w[http https].freeze
    RELATIVE_IMAGE_NAME = /\A[^:\\]+\.(?:png|jpe?g|gif|webp|svg|avif)(?:\?.*)?\z/i
    private_constant :UNSAFE_CHARACTERS, :DECODED_CONTROL_CHARACTERS, :ALLOWED_AVATAR_SCHEMES, :RELATIVE_IMAGE_NAME

    module_function

    def normalize_relative_path(path)
      return if path.blank?

      value = path.to_s
      uri = parse_safe_uri(value)
      return unless uri && relative_return_to?(uri)

      uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
    end

    def safe_avatar_url(url)
      return if url.blank?

      value = url.to_s.strip
      uri = parse_safe_uri(value)
      return unless uri
      return value if relative_image_url?(value, uri)
      return unless http_avatar_uri?(uri)

      value
    end

    def parse_safe_uri(value)
      return if value.match?(UNSAFE_CHARACTERS)

      uri = URI.parse(value)
      return if decoded_control_character?(uri)

      uri
    rescue URI::InvalidURIError
      nil
    end
    private_class_method :parse_safe_uri

    def relative_return_to?(uri)
      uri.scheme.blank? && uri.host.blank? && uri.path&.start_with?("/") && !uri.path.start_with?("//")
    end
    private_class_method :relative_return_to?

    def relative_image_url?(value, uri)
      return false if value.start_with?("//")
      return false unless uri.path.present? && uri.scheme.nil?

      value.start_with?("/") || value.match?(RELATIVE_IMAGE_NAME)
    end
    private_class_method :relative_image_url?

    def http_avatar_uri?(uri)
      ALLOWED_AVATAR_SCHEMES.include?(uri.scheme) && uri.userinfo.blank? && uri.host.present?
    end
    private_class_method :http_avatar_uri?

    def decoded_control_character?(uri)
      [uri.path, uri.query, uri.fragment].compact.any? do |part|
        decoded = CGI.unescape(part).b
        next true if decoded.match?(/[\x00-\x1F\x7F]/n)

        utf8 = decoded.dup.force_encoding(Encoding::UTF_8)
        utf8.valid_encoding? && utf8.match?(DECODED_CONTROL_CHARACTERS)
      end
    end
    private_class_method :decoded_control_character?
  end
end
