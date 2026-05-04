# frozen_string_literal: true

module RecordingStudioCommentable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    include RecordingStudioCommentable::RecordableDisplayHelper

    protect_from_forgery with: :exception unless defined?(::ApplicationController)
    layout "recording_studio_commentable/application"

    helper_method :current_recording_studio_actor
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
  end
end
