# frozen_string_literal: true

module RecordingStudioCommentable
  module Api
    class Create < RecordingStudioApi::Services::ResourceOperations::Create
      def call
        if (cached = cached_idempotent_response)
          return cached
        end

        parent_recording = parent_recording_for_create
        authorize_access!(parent_recording, role: :edit)

        result = RecordingStudioCommentable::Services::CreateComment.call(
          parent_recording: parent_recording,
          body: resource_attributes[:body],
          author: write_actor
        )
        Result.raise_for!(result)

        created_recording = RecordingStudioCommentable::Api.recording_for(result.value)
        payload = {
          json: serialize_recording(created_recording, context: relationship_context_for([created_recording])),
          status: :created
        }
        store_idempotent_response(payload)
        payload
      end
    end
  end
end
