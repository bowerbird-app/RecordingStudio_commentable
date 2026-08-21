# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    # Host verb for enabling threaded comments on a recordable type.
    #
    # Installing recording_studio_commentable registers `:commentable` at boot.
    # It does not enable the capability. Hosts opt each recordable in:
    #
    #   include RecordingStudio::Capabilities::Commentable.to(**opts)
    #
    # Option validation stays in this gem. `.to` is a thin wrapper around
    # RecordingStudio::Capabilities.include_for and does not register the
    # capability.
    module Commentable
      def self.to(**options)
        RecordingStudioCommentable::CommentableOptions.validate!(options)
        RecordingStudio::Capabilities.include_for(:commentable, **options)
      end
    end
  end
end

module RecordingStudioCommentable
  # Validates capability options before they are stored by core's include_for.
  module CommentableOptions
    module_function

    def validate!(options)
      raise ArgumentError, "commentable options must be a hash, got #{options.class}" unless options.is_a?(Hash)

      options.each_key do |key|
        next if key.is_a?(Symbol)

        raise ArgumentError, "commentable option keys must be symbols, got #{key.inspect}"
      end

      options
    end
  end

  # Backward-compatible alias. Including this still enables `:commentable`
  # through the same `.to` / `include_for` path.
  #
  #   include RecordingStudioCommentable::Commentable
  module Commentable
    extend ActiveSupport::Concern

    included do
      include RecordingStudio::Capabilities::Commentable.to
    end

    def commentable?
      true
    end

    class_methods do
      def commentable?
        true
      end
    end
  end
end
