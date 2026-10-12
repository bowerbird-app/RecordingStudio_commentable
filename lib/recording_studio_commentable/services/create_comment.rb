# frozen_string_literal: true

module RecordingStudioCommentable
  module Services
    # Creates a new comment recording under a parent recording.
    #
    # When RecordingStudio is available, creates a child recording via
    # parent_recording.record(Comment). Otherwise falls back to creating
    # a Comment directly (useful in test environments).
    #
    # @example
    #   result = CreateComment.call(
    #     parent_recording: recording,
    #     body: "Great work!",
    #     author: current_user
    #   )
    #   result.success? # => true
    #   result.value    # => the Comment instance
    #
    class CreateComment < BaseService
      def initialize(parent_recording:, body:, author: nil)
        @parent_recording = parent_recording
        @body = body
        @author = author
      end

      private

      def perform
        return failure(body_blank_error) if @body.blank?

        comment = build_comment
        return failure(comment_invalid_error, errors: comment.errors.full_messages) unless comment.valid?

        record_comment(comment)
      rescue StandardError => e
        failure(e)
      end

      def body_blank_error
        I18n.t(
          "recording_studio.commentable.errors.body_blank",
          default: "Body cannot be blank"
        )
      end

      def comment_invalid_error
        I18n.t(
          "recording_studio.commentable.errors.comment_invalid",
          default: "Comment is invalid"
        )
      end

      def build_comment
        RecordingStudioCommentable::Comment.new(body: @body, author: @author)
      end

      def record_comment(comment)
        if recording_studio_available?
          created_comment = nil
          @parent_recording.record(comment.class, parent_recording: @parent_recording) do |c|
            c.body = @body
            c.author = @author
            created_comment = c
          end
          success(created_comment)
        else
          # Fallback: persist directly (test / standalone environments)
          comment.save!
          success(comment)
        end
      end

      def recording_studio_available?
        defined?(RecordingStudio) &&
          @parent_recording.respond_to?(:record)
      end

      def service_args
        { body: @body, author: @author }
      end
    end
  end
end
