# frozen_string_literal: true

module RecordingStudioCommentable
  module Services
    # Updates a comment via the RecordingStudio revise pattern.
    #
    # In RecordingStudio, recordables are immutable — updating creates a new
    # snapshot (revision) while the recording ID stays the same.
    #
    # @example
    #   result = UpdateComment.call(
    #     comment_recording: recording,
    #     root_recording: root,
    #     body: "Updated text",
    #     actor: current_user
    #   )
    #
    class UpdateComment < BaseService
      def initialize(comment_recording:, root_recording:, body:, actor: nil)
        @comment_recording = comment_recording
        @root_recording = root_recording
        @body = body
        @actor = actor
      end

      private

      def perform
        return failure("Body cannot be blank") if @body.blank?

        if revise_available?
          revise_via_recording_studio
        else
          update_directly
        end
      rescue StandardError => e
        failure(e)
      end

      def revise_via_recording_studio
        updated_comment = nil
        @root_recording.revise(@comment_recording) do |new_comment|
          new_comment.body = @body
          updated_comment = new_comment
        end
        success(updated_comment)
      end

      def update_directly
        comment = @comment_recording.respond_to?(:recordable) ? @comment_recording.recordable : @comment_recording
        comment.body = @body
        return failure("Comment is invalid", errors: comment.errors.full_messages) unless comment.valid?

        comment.save!
        success(comment)
      end

      def revise_available?
        defined?(RecordingStudio) &&
          @root_recording.respond_to?(:revise)
      end

      def service_args
        { body: @body, actor: @actor }
      end
    end
  end
end
