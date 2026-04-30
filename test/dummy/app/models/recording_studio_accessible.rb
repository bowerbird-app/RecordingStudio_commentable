# frozen_string_literal: true

module RecordingStudioAccessible
  class << self
    def authorized?(actor:, recording:, role:)
      RecordingStudio::Services::AccessCheck.allowed?(
        actor: actor,
        recording: recording,
        role: role
      )
    end
  end
end