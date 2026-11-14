# frozen_string_literal: true

if defined?(RecordingStudioAccessible)
  RecordingStudioAccessible.configure do |config|
    config.access_actor_types = ["User", "RecordingStudioApi::ApiClient"].uniq
  end
end
