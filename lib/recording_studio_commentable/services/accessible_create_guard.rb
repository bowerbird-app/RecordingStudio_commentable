# frozen_string_literal: true

module RecordingStudioCommentable
  module Services
    # Shared Accessible :edit and :commentable checks for posting comments.
    # HTTP and direct service calls use the same gate as CommentsController.
    module AccessibleCreateGuard
      def self.commentable?(recording)
        recordable = recording.try(:recordable)
        type = recordable&.class
        type && RecordingStudio.capability_enabled?(:commentable, for: type)
      end

      def self.authorized?(actor:, recording:)
        return false unless defined?(RecordingStudioAccessible)

        RecordingStudioAccessible.authorized?(
          actor: actor,
          recording: recording,
          role: :edit
        )
      end

      private

      def commentable_enabled?
        AccessibleCreateGuard.commentable?(accessible_create_recording)
      end

      def accessible_create?
        AccessibleCreateGuard.authorized?(
          actor: @author,
          recording: accessible_create_recording
        )
      end

      def accessible_create_recording
        recording = @parent_recording
        comment_type = "RecordingStudioCommentable::Comment"

        while recording.respond_to?(:recordable_type) && recording.recordable_type == comment_type
          parent = recording.respond_to?(:parent_recording) ? recording.parent_recording : nil
          break unless parent

          recording = parent
        end

        recording
      end

      def comments_not_enabled_error
        RecordingStudio.t("recording_studio.commentable.errors.comments_not_enabled")
      end

      def not_allowed_post_error
        RecordingStudio.t("recording_studio.commentable.errors.not_allowed_post")
      end
    end
  end
end
