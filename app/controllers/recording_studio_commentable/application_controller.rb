# frozen_string_literal: true

module RecordingStudioCommentable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    include RecordingStudioCommentable::CommentBodyHelper
    include RecordingStudioCommentable::CommentRoutesHelper
    include RecordingStudioCommentable::RecordableDisplayHelper

    protect_from_forgery with: :exception unless defined?(::ApplicationController)
    layout :commentable_layout

    helper_method :current_recording_studio_actor
    helper_method :commentable_reply_comment_path
    helper_method :truncate_comment_body
    helper_method :recordable_display_title

    private

    # Returns the current actor (user / service account).
    # Defers to the host app's Current.actor if available.
    def current_recording_studio_actor
      if defined?(Current) && Current.respond_to?(:actor)
        Current.actor
      elsif respond_to?(:current_user, true)
        current_user
      end
    end

    def require_actor!
      return if current_recording_studio_actor

      if request.format.html?
        redirect_to(main_app.root_path, alert: "You must be signed in.")
      else
        head :unauthorized
      end
    end

    def commentable_layout
      RecordingStudioCommentable.configuration.layout.presence || "recording_studio_commentable/application"
    end
  end
end
