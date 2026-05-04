# frozen_string_literal: true

require "recording_studio_commentable/version"
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

    def normalize_configuration(config)
      return Configuration.new unless config
      return config if config.respond_to?(:rich_text_comments) &&
                       config.respond_to?(:layout) &&
                       config.respond_to?(:recordable_display_attributes) &&
                       config.respond_to?(:author_display_attributes) &&
                       config.respond_to?(:author_avatar_attributes)

      upgraded = Configuration.new
      upgraded.timeout = config.timeout if config.respond_to?(:timeout)
      upgraded.layout = config.layout if config.respond_to?(:layout)
      upgraded.rich_text_comments = config.rich_text_comments if config.respond_to?(:rich_text_comments)
      if config.respond_to?(:recordable_display_attributes)
        upgraded.recordable_display_attributes = config.recordable_display_attributes
      end
      if config.respond_to?(:author_display_attributes)
        upgraded.author_display_attributes = config.author_display_attributes
      end
      if config.respond_to?(:author_avatar_attributes)
        upgraded.author_avatar_attributes = config.author_avatar_attributes
      end
      upgraded.instance_variable_set(:@hooks, config.hooks) if config.respond_to?(:hooks)
      upgraded
    end
  end
end
