# frozen_string_literal: true

module RecordingStudioCommentable
  module Services
    # Shared Accessible :admin check for comment edit and delete.
    # HTTP and direct service calls use the same gate.
    module AccessibleAdminGuard
      def self.authorized?(actor:, recording:)
        return false unless defined?(RecordingStudioAccessible)
        return false unless recording

        RecordingStudioAccessible.authorized?(
          actor: actor,
          recording: recording,
          role: :admin
        )
      end

      def self.recording_for(comment_recording:, root_recording: nil)
        parent = comment_recording.respond_to?(:parent_recording) ? comment_recording.parent_recording : nil
        parent || root_recording
      end

      private

      def accessible_admin?
        return false unless defined?(RecordingStudioAccessible)

        recording = accessible_admin_recording
        return false unless recording

        AccessibleAdminGuard.authorized?(actor: @actor, recording: recording)
      end

      def accessible_admin_recording
        AccessibleAdminGuard.recording_for(
          comment_recording: @comment_recording,
          root_recording: @root_recording
        )
      end

      def not_allowed_edit_error
        RecordingStudio.t("recording_studio.commentable.errors.not_allowed_edit")
      end
    end
  end
end
