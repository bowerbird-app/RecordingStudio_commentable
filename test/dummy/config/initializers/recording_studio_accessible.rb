# frozen_string_literal: true

if defined?(RecordingStudioAccessible)
  RecordingStudioAccessible.configure do |config|
    config.access_actor_types = ["User"]
  end
end
