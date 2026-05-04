# frozen_string_literal: true

module RecordingStudioCommentable
  module DisplayAttributeResolver
    module_function

    def configured_attribute_for(object, mappings)
      return unless object

      class_name = object.class.name.to_s
      mappings[class_name] || mappings[class_name.demodulize]
    end

    def string_value_for(object, mappings:, fallback_attributes: [])
      return unless object

      configured_attribute = configured_attribute_for(object, mappings)
      configured_value = string_attribute_value(object, configured_attribute)
      return configured_value if configured_value.present?

      fallback_attributes.each do |attribute_name|
        fallback_value = string_attribute_value(object, attribute_name)
        return fallback_value if fallback_value.present?
      end

      nil
    end

    def mapping_for_configuration(accessor_name)
      config = RecordingStudioCommentable.configuration
      return {} unless config.respond_to?(accessor_name)

      config.public_send(accessor_name) || {}
    end

    def string_attribute_value(object, attribute_name)
      return if object.nil? || attribute_name.blank?
      return unless object.respond_to?(attribute_name)

      object.public_send(attribute_name).to_s.squish.presence
    end
  end
end