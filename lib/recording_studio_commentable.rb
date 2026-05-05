# frozen_string_literal: true

require "recording_studio_commentable/version"
require "recording_studio_commentable/comment_count"
require "recording_studio_commentable/configuration"
require "recording_studio_commentable/comment_body_helper"
require "recording_studio_commentable/display_attribute_resolver"
require "recording_studio_commentable/recordable_display_helper"
require "recording_studio_commentable/capability"
require "recording_studio_commentable/services/base_service"
require "recording_studio_commentable/services/create_comment"
require "recording_studio_commentable/services/update_comment"
require "recording_studio_commentable/services/destroy_comment"
require "recording_studio_commentable/engine"

module RecordingStudioCommentable
  class << self
    def configuration
      @configuration = normalize_configuration(@configuration)
    end

    def configure
      yield(configuration) if block_given?
    end

    private

    MIGRATEABLE_ATTRIBUTES = %i[
      timeout
      use_recording_studio_trashable_for_destroy
      layout
      rich_text_comments
      recordable_display_attributes
      author_display_attributes
      author_avatar_attributes
    ].freeze
    private_constant :MIGRATEABLE_ATTRIBUTES

    def normalize_configuration(config)
      return Configuration.new unless config
      return config if config.is_a?(Configuration)

      upgraded = Configuration.new
      MIGRATEABLE_ATTRIBUTES.each do |attr|
        next unless config.respond_to?(attr)

        upgraded.public_send(:"#{attr}=", config.public_send(attr))
      end
      upgraded.instance_variable_set(:@hooks, config.hooks) if config.respond_to?(:hooks)
      upgraded
    end
  end
end
