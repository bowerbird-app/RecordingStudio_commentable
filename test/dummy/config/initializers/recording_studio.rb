# frozen_string_literal: true

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes).
  # API 1.15 declares AdminApi only when an admin root type is configured.
  # This dummy has none, so AdminApi stays off the list. Listing it raises
  # MissingRecordableDeclaration at boot.
  host_types = [ "Workspace", "Folder", "Page", "RecordingStudioCommentable::Comment" ]
  config.recordable_types = host_types
  config.app_name = "Comments" if config.respond_to?(:app_name=)

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Core 7 fails closed without a write gate. create_root_recording! calls this
  # with recording, root_recording, and parent_recording all nil. Allow the
  # write when an actor is present.
  config.authorize_write = lambda { |actor:, **|
    actor.present?
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
