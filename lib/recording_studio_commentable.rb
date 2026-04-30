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
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
