# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = [ "Workspace", "Folder", "Page", "RecordingStudioCommentable::Comment" ]
  config.app_name = "Comments" if config.respond_to?(:app_name=)

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Core 6.5 fails closed without a write gate. Check Accessible :edit on the
  # recording being written. Empty trees still allow the first owner bootstrap.
  config.authorize_write = lambda { |actor:, root_recording:, recording: nil, parent_recording: nil, **|
    next false unless actor
    next false unless defined?(RecordingStudioAccessible)

    target = recording || parent_recording || root_recording
    next false unless target
    next true if RecordingStudioAccessible.authorized?(actor: actor, recording: target, role: :edit)

    scope = root_recording || target
    RecordingStudioAccessible.access_recordings_for(scope).none?
  }

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup

  # Built-in capabilities remain disabled until you opt a recordable type into
  # them with include RecordingStudio::Capabilities::Commentable.to.
end
