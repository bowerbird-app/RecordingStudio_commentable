# frozen_string_literal: true

module RecordingStudioCommentable
  module CommentComposer
    class Component < ViewComponent::Base
      def initialize(comment:, url:, cancel_path: nil, parent_comment_id: nil)
        super()
        @comment = comment
        @url = url
        @cancel_path = cancel_path
        @parent_comment_id = parent_comment_id
      end

      private

      attr_reader :comment, :url, :cancel_path, :parent_comment_id

      def rich_text_comments_enabled?
        RecordingStudioCommentable.configuration.rich_text_comments_enabled?
      end

      def rich_text_options
        RecordingStudioCommentable.configuration.rich_text_comment_editor_options(placeholder: "Write your comment...")
      end

      def submit_label
        comment.new_record? ? "Post comment" : "Save changes"
      end

      def actor_name
        actor = helpers.current_recording_studio_actor
        return "You" unless actor

        actor.respond_to?(:display_name) ? actor.display_name : actor.to_s.presence || "You"
      end
    end
  end
end