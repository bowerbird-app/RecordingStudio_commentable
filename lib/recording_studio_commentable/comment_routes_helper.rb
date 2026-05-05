module RecordingStudioCommentable
  module CommentRoutesHelper
    def commentable_reply_comment_path(comment_recording, **options)
      recording_studio_commentable.reply_comment_path(comment_recording, options)
    end
  end
end