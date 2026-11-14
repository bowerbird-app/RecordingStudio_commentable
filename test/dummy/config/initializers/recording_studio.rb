# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes).
  # AdminApi declares on eager load; register it so CI declaration checks pass.
  host_types = [ "Workspace", "Folder", "Page", "RecordingStudioCommentable::Comment" ]
  host_types << "RecordingStudioApi::AdminApi" if defined?(RecordingStudioApi)
  config.recordable_types = host_types
  config.app_name = "Comments" if config.respond_to?(:app_name=)

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Core 6.5 fails closed without a write gate. Delegate to Accessible :edit.
  # Owner grants are seeded with bootstrap_owner_access! / grant_access; those
  # Access writes already run inside Accessible's grant path. Allow the
  # AccessCreationContext only for Access rows, not every write during bootstrap.
  config.authorize_write = lambda { |actor:, root_recording:, recording: nil, parent_recording: nil, recordable: nil, **|
    next false unless defined?(RecordingStudioAccessible)

    target = recording || parent_recording || root_recording
    next false unless target
    next true if defined?(RecordingStudio::Access) &&
                 recordable.is_a?(RecordingStudio::Access) &&
                 RecordingStudioAccessible::AccessCreationContext.allowed?

    api_engine_recordable = defined?(RecordingStudioApi) && recordable.class.name.to_s.start_with?("RecordingStudioApi::")
    next true if api_engine_recordable && RecordingStudioAccessible::AccessCreationContext.allowed?

    RecordingStudioAccessible.authorized?(actor: actor, recording: target, role: :edit)
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
