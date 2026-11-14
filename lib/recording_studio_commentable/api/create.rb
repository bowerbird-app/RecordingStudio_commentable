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
        assert_commentable!(parent_recording)

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

      private

      def assert_commentable!(recording)
        current = recording
        comment_type = RecordingStudioCommentable::Api::RECORDABLE_TYPE

        while current
          type = current.try(:recordable)&.class
          return if type && RecordingStudio.capability_enabled?(:commentable, for: type)
          break unless current.respond_to?(:recordable_type) && current.recordable_type == comment_type

          current = current.respond_to?(:parent_recording) ? current.parent_recording : nil
        end

        raise RecordingStudioApi::AuthorizationError,
              RecordingStudio.t("recording_studio.commentable.flashes.comments_not_enabled")
      end
    end
  end
end
