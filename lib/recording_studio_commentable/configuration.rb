# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCommentable
  class Configuration
    attr_accessor :timeout, :rich_text_comments
    attr_reader :hooks, :recordable_display_attributes, :author_display_attributes, :author_avatar_attributes

    def initialize
      @timeout = 5
      @rich_text_comments = false
      @recordable_display_attributes = {}
      @author_display_attributes = {}
      @author_avatar_attributes = {}
      @hooks = Hooks.new
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
  end
end
