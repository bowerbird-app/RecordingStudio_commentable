# frozen_string_literal: true

require "recording_studio_commentable/display_attribute_resolver"

module RecordingStudioCommentable
  module RecordableDisplayHelper
    def recordable_display_title(recordable_or_recording, missing: "Unknown item")
      recordable = extract_recordable(recordable_or_recording)
      return missing unless recordable

      configured_value = configured_display_value_for(recordable)
      return configured_value if configured_value.present?

      fallback_display_value_for(recordable) || missing
    end

    private

    def extract_recordable(recordable_or_recording)
      return unless recordable_or_recording

      if recordable_or_recording.respond_to?(:recordable)
        recordable_or_recording.recordable
      else
        recordable_or_recording
      end
    end

    def configured_display_value_for(recordable)
      attribute_name = configured_display_attribute_for(recordable)
      return unless attribute_name

      display_attribute_value(recordable, attribute_name)
    end

    def configured_display_attribute_for(recordable)
      return unless recordable

      RecordingStudioCommentable::DisplayAttributeResolver.configured_attribute_for(recordable, configured_display_attributes)
    end

    def configured_display_attributes
      RecordingStudioCommentable::DisplayAttributeResolver.mapping_for_configuration(:recordable_display_attributes)
    end

    def fallback_display_value_for(recordable)
      RecordingStudioCommentable::DisplayAttributeResolver.string_value_for(
        recordable,
        mappings: {},
        fallback_attributes: %i[title name]
      ) || recordable.class.name
    end

    def display_attribute_value(recordable, attribute_name)
      RecordingStudioCommentable::DisplayAttributeResolver.string_attribute_value(recordable, attribute_name)
    end
  end
end
