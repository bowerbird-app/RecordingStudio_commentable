# frozen_string_literal: true

module RecordingStudioCommentable
  module Api
    class Destroy < RecordingStudioApi::Services::ResourceOperations::Destroy
      def call
        comment_recording = RecordingStudioCommentable::Api.member_recording(context, include_trashed: true)
        authorize_access!(
          RecordingStudioCommentable::Api.admin_access_recording(comment_recording),
          role: :admin,
          include_trashed: true
        )

        serialized_recording = serialize_recording(comment_recording)
        result = RecordingStudioCommentable::Services::DestroyComment.call(
          comment_recording: comment_recording,
          root_recording: comment_recording.root_recording || comment_recording,
          actor: write_actor
        )
        Result.raise_for!(result)

        { json: serialize_delete_result(serialized_recording, deleted_via: "trashed") }
      end
    end
  end
end
