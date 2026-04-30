# frozen_string_literal: true

module RecordingStudioCommentable
  class HomeController < ApplicationController
    def index
      @workspace = Workspace.first if defined?(Workspace)
      @root_recording = RecordingStudio::Recording.unscoped.find_by(
        recordable: @workspace,
        parent_recording_id: nil
      )

      scenario_titles = [
        "Reference Folder",
        "Quinn owns this document",
        "Admin User owns this document",
        "Publicly accessible document"
      ]

      @scenario_recordings = RecordingStudio::Recording.unscoped
                                                       .where(root_recording_id: @root_recording&.id)
                                                       .where(recordable_type: %w[Folder Page])
                                                       .where(trashed_at: nil)
                                                       .includes(:recordable)
                                                       .select { |recording| scenario_titles.include?(recording.recordable&.try(:name) || recording.recordable&.try(:title)) }
                                                       .sort_by do |recording|
        label = recording.recordable&.try(:name) || recording.recordable&.try(:title)
        scenario_titles.index(label) || scenario_titles.length
      end

      @new_comment = RecordingStudioCommentable::Comment.new
    end
  end
end
