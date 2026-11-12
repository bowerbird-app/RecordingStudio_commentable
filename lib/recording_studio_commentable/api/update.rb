# frozen_string_literal: true

module RecordingStudioCommentable
  module Api
    class Update < RecordingStudioApi::Services::ResourceOperations::Update
      def call
        reject_parent_id_input!
        comment_recording = RecordingStudioCommentable::Api.member_recording(context)
        authorize_access!(RecordingStudioCommentable::Api.admin_access_recording(comment_recording), role: :admin)

        result = RecordingStudioCommentable::Services::UpdateComment.call(
          comment_recording: comment_recording,
          root_recording: comment_recording.root_recording || comment_recording,
          body: comment_body_for_update(comment_recording),
          actor: write_actor
        )
        Result.raise_for!(result)

        updated_recording = RecordingStudioCommentable::Api.recording_for(result.value).reload
        { json: serialize_recording(updated_recording, context: relationship_context_for([updated_recording])) }
      end

      private

      def comment_body_for_update(comment_recording)
        attributes = resource_attributes
        return attributes[:body] if attributes.key?(:body)

        payload = request_payload
        payload[:body] || payload["body"] || params[:body] || params["body"] || comment_recording.recordable.body
      end
    end
  end
end
