# frozen_string_literal: true

module RecordingStudioCommentable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    include RecordingStudioCommentable::CommentBodyHelper
    include RecordingStudioCommentable::CommentRoutesHelper
    include RecordingStudioCommentable::RecordableDisplayHelper

    protect_from_forgery with: :exception unless defined?(::ApplicationController)
    include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)
    helper RecordingStudio::LayoutHelper if defined?(RecordingStudio::LayoutHelper)
    layout :commentable_layout

    helper_method :current_recording_studio_actor
    helper_method :commentable_recording_comments_path
    helper_method :commentable_all_recording_comments_path
    helper_method :commentable_new_recording_comment_path
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
      RecordingStudioCommentable.configuration.layout.presence || "recording_studio/default_layout"
    end

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

    def commentable_route_options(options)
      normalized = options.to_h
      return normalized if normalized.key?(:anchor)

      anchor = RecordingStudioCommentable.configuration.route_anchor
      anchor.present? ? normalized.merge(anchor: anchor) : normalized
    end
  end
end
