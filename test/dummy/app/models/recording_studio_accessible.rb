# frozen_string_literal: true

module RecordingStudioAccessible
  class << self
    def authorized?(actor:, recording:, role:)
      return Authorization.allowed?(actor: actor, recording: recording, role: role) if const_defined?(:Authorization)

      false
    end
  end
end