# frozen_string_literal: true

module RecordingStudioCommentable
  module Services
    # Shared Accessible :admin check for comment edit and delete.
    # HTTP and direct service calls use the same gate.
    module AccessibleAdminGuard
      private

      def accessible_admin?
        return false unless defined?(RecordingStudioAccessible)

        recording = accessible_admin_recording
        return false unless recording

        RecordingStudioAccessible.authorized?(
          actor: @actor,
          recording: recording,
          role: :admin
        )
      end

      def accessible_admin_recording
        parent = @comment_recording.respond_to?(:parent_recording) ? @comment_recording.parent_recording : nil
        parent ||= @root_recording
        return parent unless parent.respond_to?(:root_recording)

        parent.root_recording || parent
      end

      def not_allowed_edit_error
        RecordingStudio.t("recording_studio.commentable.errors.not_allowed_edit")
      end
    end
  end
end
