# frozen_string_literal: true

module RecordingStudioCommentable
  class HomeController < ApplicationController
    before_action :require_actor!

    def index
      @external_back_path = scenarios_target_path
      @comment_entries = visible_comment_entries
    end

    private

    def visible_comment_entries
      return [] unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording
        .where(recordable_type: "RecordingStudioCommentable::Comment")
        .where(trashed_at: nil)
        .includes(:recordable, :parent_recording)
        .order(created_at: :desc)
        .filter_map do |comment_recording|
          parent_recording = comment_recording.parent_recording
          next unless authorized_to_view?(parent_recording)

          {
            comment_recording: comment_recording,
            parent_recording: parent_recording,
            parent_title: recordable_title(parent_recording)
          }
        end
    end

    def authorized_to_view?(recording)
      return false unless recording
      return true unless defined?(RecordingStudioAccessible)

      RecordingStudioAccessible.authorized?(
        actor: current_recording_studio_actor,
        recording: recording,
        role: :view
      )
    end

    def recordable_title(recording)
      recordable = recording.respond_to?(:recordable) ? recording.recordable : nil
      return "Unknown item" unless recordable

      recordable.try(:title) || recordable.try(:name) || recordable.class.name
    end

    def scenarios_target_path
      return main_app.scenarios_path if main_app.respond_to?(:scenarios_path)

      main_app.root_path
    end
  end
end
