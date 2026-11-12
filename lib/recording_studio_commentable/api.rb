# frozen_string_literal: true

module RecordingStudioCommentable
  module Api
    RECORDABLE_TYPE = "RecordingStudioCommentable::Comment"
    OPERATIONS = %i[index show create update destroy].freeze
    WRITABLE_ATTRIBUTES = %i[body].freeze
    OUTPUT_KEYS = %i[body author_display_name].freeze
    SERIALIZER = lambda { |comment, **|
      {
        body: comment.body,
        author_display_name: comment.author_display_name
      }
    }.freeze
    COMMENT_COUNT = lambda { |context|
      RecordingStudioCommentable::CommentCount.for_recording(context.recording)
    }
    FIELDS = {
      comment_count: {
        resolver: COMMENT_COUNT,
        include: true,
        openapi: { type: "integer" }
      }
    }.freeze

    class << self
      def register!
        return unless recording_studio_api_available?

        require_relative "api/result"
        require_relative "api/create"
        require_relative "api/update"
        require_relative "api/destroy"

        register_type!
        register_handlers!
        true
      end

      def recording_studio_api_available?
        defined?(RecordingStudioApi) &&
          RecordingStudioApi.respond_to?(:register_recordable_type_api) &&
          RecordingStudioApi.respond_to?(:register_resource_handler)
      end

      def recording_for(comment)
        return comment.recording if comment.respond_to?(:recording) && comment.recording

        RecordingStudio::Recording.find_by!(
          recordable_type: comment.class.name,
          recordable_id: comment.id
        )
      end

      def member_recording(context, include_trashed: false)
        return context.recording if context.recording

        found = context.access_grant.accessible_recordings(include_trashed: include_trashed).find_by(id: context.id)
        raise RecordingStudioApi::NotFoundError, "Resource was not found in this API scope" if found.nil?

        found
      end

      def admin_access_recording(comment_recording)
        RecordingStudioCommentable::Services::AccessibleAdminGuard.recording_for(
          comment_recording: comment_recording,
          root_recording: comment_recording
        )
      end

      private

      def register_type!
        RecordingStudioApi.register_recordable_type_api(
          RECORDABLE_TYPE,
          serializer: SERIALIZER,
          output_keys: OUTPUT_KEYS,
          writable_attributes: WRITABLE_ATTRIBUTES,
          operations: OPERATIONS,
          auto_capability_actions: false,
          fields: FIELDS,
          relationships: {
            replies: {
              source: :children,
              child_type: RECORDABLE_TYPE,
              many: true,
              include: :request,
              serializer: SERIALIZER,
              output_keys: OUTPUT_KEYS,
              limit: 50,
              order: { created_at: :asc },
              endpoints: %i[index show create]
            }
          },
          openapi: { tags: ["Comments"] }
        )
      end

      def register_handlers!
        register_handler(:create, Create)
        register_handler(:update, Update)
        register_handler(:destroy, Destroy)
      end

      def register_handler(action, handler)
        return if RecordingStudioApi.resource_handler(RECORDABLE_TYPE, action)

        RecordingStudioApi.register_resource_handler(
          RECORDABLE_TYPE,
          action,
          handler: handler
        )
      end
    end
  end
end
