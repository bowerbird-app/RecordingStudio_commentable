# frozen_string_literal: true

require "uri"

module RecordingStudioCommentable
  module PathSafety
    module_function

    def normalize_relative_path(path)
      return if path.blank?

      uri = URI.parse(path.to_s)
      return if uri.scheme.present? || uri.host.present? || uri.path.nil? || !uri.path.start_with?("/")

      uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
    rescue URI::InvalidURIError
      nil
    end
  end
end
