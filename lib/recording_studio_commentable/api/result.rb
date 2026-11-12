# frozen_string_literal: true

module RecordingStudioCommentable
  module Api
    module Result
      module_function

      def raise_for!(result)
        return if result.success?

        message = result.error.to_s
        raise RecordingStudioApi::AuthorizationError, message if authorization_failure?(message)

        raise RecordingStudioApi::InvalidActionInputError, message
      end

      def authorization_failure?(message)
        [
          RecordingStudio.t("recording_studio.commentable.errors.not_allowed_post"),
          RecordingStudio.t("recording_studio.commentable.errors.not_allowed_edit"),
          RecordingStudio.t("recording_studio.commentable.errors.comments_not_enabled")
        ].include?(message)
      end
    end
  end
end
