# frozen_string_literal: true

module RecordingStudioCommentable
  module Services
    # Destroys (trashes) a comment recording.
    #
    # In RecordingStudio, deletion is a soft trash operation on the recording.
    # The comment data is preserved in history; only the recording is trashed.
    #
    # @example
    #   result = DestroyComment.call(
    #     comment_recording: recording,
    #     root_recording: root,
    #     actor: current_user
    #   )
    #
    class DestroyComment < BaseService
      def initialize(comment_recording:, root_recording:, actor: nil)
        @comment_recording = comment_recording
        @root_recording = root_recording
        @actor = actor
      end

      private

      def perform
        if trash_available?
          trash_via_recording_studio
        else
          destroy_directly
        end
      rescue StandardError => e
        failure(e)
      end

      def trash_via_recording_studio
        @root_recording.trash(@comment_recording, actor: @actor)
        success(@comment_recording)
      end

      def destroy_directly
        comment = @comment_recording.respond_to?(:recordable) ? @comment_recording.recordable : @comment_recording
        comment.destroy!
        success(comment)
      end

      def trash_available?
        defined?(RecordingStudio) &&
          @root_recording.respond_to?(:trash)
      end

      def service_args
        { actor: @actor }
      end
    end
  end
end
