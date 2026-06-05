module RecordingStudioCommentable
  module CommentRoutesHelper
    def commentable_recording_comments_path(recording, **options)
      main_app.recording_comments_path(recording, commentable_route_options(options))
    end

    def commentable_all_recording_comments_path(recording, **options)
      main_app.all_recording_comments_path(recording, commentable_route_options(options))
    end

    def commentable_new_recording_comment_path(recording, **options)
      main_app.new_recording_comment_path(recording, commentable_route_options(options))
    end

    def commentable_reply_comment_path(comment_recording, **options)
      recording_studio_commentable.reply_comment_path(comment_recording, commentable_route_options(options))
    end

    private

    def commentable_route_options(options)
      normalized = options.to_h
      return normalized if normalized.key?(:anchor)

      anchor = RecordingStudioCommentable.configuration.route_anchor
      anchor.present? ? normalized.merge(anchor: anchor) : normalized
    end
  end
end