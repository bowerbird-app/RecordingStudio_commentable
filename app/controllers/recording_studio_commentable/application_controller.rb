# frozen_string_literal: true

module RecordingStudioCommentable
  class ApplicationController < (defined?(::ApplicationController) ? ::ApplicationController : ActionController::Base)
    protect_from_forgery with: :exception unless defined?(::ApplicationController)
    layout "recording_studio_commentable/application"

    helper_method :current_recording_studio_actor

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

    def root_recording_for(recording)
      return recording unless recording.respond_to?(:root_recording)

      recording.root_recording || recording
    end
  end
end
