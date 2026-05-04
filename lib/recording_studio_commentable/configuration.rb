# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCommentable
  class Configuration
    RICH_TEXT_COMMENT_MODES = {
      true => :toolbar,
      false => false,
      nil => false,
      "" => false,
      :toolbar => :toolbar,
      "toolbar" => :toolbar,
      :selection => :selection,
      "selection" => :selection
    }.freeze

    attr_accessor :timeout
    attr_reader :rich_text_comments, :hooks, :recordable_display_attributes, :author_display_attributes,
                :author_avatar_attributes, :layout

    def initialize
      @timeout = 5
      @rich_text_comments = false
      @layout = nil
      @recordable_display_attributes = {}
      @author_display_attributes = {}
      @author_avatar_attributes = {}
      @hooks = Hooks.new
    end

    def layout=(value)
      @layout = value.to_s.strip.presence
    end

    def rich_text_comments=(value)
      @rich_text_comments = normalize_rich_text_comments(value)
    end

    def rich_text_comments_enabled?
      rich_text_comments.present?
    end

    def rich_text_comment_editor_options(placeholder: nil)
      return {} unless rich_text_comments_enabled?

      {
        preset: :content,
        toolbar: rich_text_comments == :selection ? :none : :standard,
        bubble_menu: true,
        format: :html,
        placeholder: placeholder
      }.compact
    end

    def recordable_display_attributes=(value)
      @recordable_display_attributes = normalize_display_attribute_mapping(value)
    end

    def author_display_attributes=(value)
      @author_display_attributes = normalize_display_attribute_mapping(value)
    end

    def author_avatar_attributes=(value)
      @author_avatar_attributes = normalize_display_attribute_mapping(value)
    end

    def to_h
      {
        timeout: timeout,
        rich_text_comments: rich_text_comments,
        layout: layout,
        recordable_display_attributes: recordable_display_attributes.dup,
        author_display_attributes: author_display_attributes.dup,
        author_avatar_attributes: author_avatar_attributes.dup,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end

    private

    def normalize_display_attribute_mapping(value)
      return {} unless value.respond_to?(:each)

      value.each_with_object({}) do |(recordable_type, attribute_name), normalized|
        next if recordable_type.blank? || attribute_name.blank?

        normalized[recordable_type.to_s] = attribute_name.to_sym
      end
    end

    def normalize_rich_text_comments(value)
      normalized = if value.is_a?(String)
                     stripped = value.strip
                     RICH_TEXT_COMMENT_MODES.fetch(stripped, stripped.presence&.to_sym)
                   else
                     RICH_TEXT_COMMENT_MODES.fetch(value, value)
                   end

      return normalized if [false, :toolbar, :selection].include?(normalized)

      raise ArgumentError,
            "rich_text_comments must be false, true, :toolbar, or :selection, got #{value.inspect}"
    end
  end
end
