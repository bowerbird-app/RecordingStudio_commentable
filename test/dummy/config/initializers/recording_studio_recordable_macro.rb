# frozen_string_literal: true

require "recording_studio"

Rails.application.config.to_prepare do
  next unless defined?(RecordingStudio::RecordableDeclarations)

  RecordingStudio::RecordableDeclarations.install_active_record_macro!
end
