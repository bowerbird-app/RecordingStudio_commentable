# frozen_string_literal: true

require "recording_studio_commentable/version"
require "recording_studio_commentable/engine"
require "recording_studio_commentable/configuration"
require "recording_studio_commentable/capability"
require "recording_studio_commentable/services/base_service"
require "recording_studio_commentable/services/create_comment"
require "recording_studio_commentable/services/update_comment"
require "recording_studio_commentable/services/destroy_comment"

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
      return config if config.respond_to?(:rich_text_comments)

      upgraded = Configuration.new
      upgraded.timeout = config.timeout if config.respond_to?(:timeout)
      upgraded.instance_variable_set(:@hooks, config.hooks) if config.respond_to?(:hooks)
      upgraded
    end
  end
end
