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
        RecordingStudioCommentable.configuration.rich_text_comment_editor_options(placeholder: placeholder_text)
      end

      def placeholder_text
        I18n.t("recording_studio.commentable.composer.placeholder")
      end

      def submit_label
        comment.new_record? ? I18n.t("recording_studio.commentable.composer.post") : I18n.t("recording_studio.commentable.composer.save")
      end

      def actor_name
        actor = helpers.current_recording_studio_actor
        return I18n.t("recording_studio.commentable.common.you") unless actor

        actor.respond_to?(:display_name) ? actor.display_name : actor.to_s.presence || I18n.t("recording_studio.commentable.common.you")
      end
    end
  end
end