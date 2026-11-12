# frozen_string_literal: true

module RecordingStudioCommentable
  module Api
    class Update < RecordingStudioApi::Services::ResourceOperations::Update
      def call
        reject_parent_id_input!
        comment_recording = RecordingStudioCommentable::Api.member_recording(context)
        parent_recording = comment_recording.parent_recording
        raise RecordingStudioApi::NotFoundError, "Resource was not found in this API scope" if parent_recording.nil?

        access_grant.authorize!(recording: parent_recording, role: :admin)

        result = RecordingStudioCommentable::Services::UpdateComment.call(
          comment_recording: comment_recording,
          root_recording: comment_recording.root_recording || comment_recording,
          body: resource_attributes[:body],
          actor: write_actor
        )
        Result.raise_for!(result)

        updated_recording = RecordingStudioCommentable::Api.recording_for(result.value).reload
        { json: serialize_recording(updated_recording, context: relationship_context_for([updated_recording])) }
      end
    end
  end
end
