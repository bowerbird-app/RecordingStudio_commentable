class HomeController < ApplicationController
  before_action :load_workspace_context, only: %i[index scenarios]
  before_action :load_scenario_recordings, only: %i[index scenarios]

  def index
  end

  def scenarios
    @new_comment = RecordingStudioCommentable::Comment.new
  end

  private

  def load_workspace_context
    @workspace = Workspace.first
    @root_recording = RecordingStudio::Recording.unscoped.find_by(
      recordable: @workspace,
      parent_recording_id: nil
    )
  end

  def load_scenario_recordings
    scenario_titles = [
      "Reference Folder",
      "Quinn owns this document",
      "Admin User owns this document",
      "Quinn and Admin User can comment"
    ]

    @scenario_recordings = RecordingStudio::Recording.unscoped
      .where(parent_recording_id: nil)
      .where(recordable_type: ["Folder", "Page"])
      .where(trashed_at: nil)
      .includes(:recordable)
      .select { |recording| scenario_titles.include?(recording.recordable&.try(:name) || recording.recordable&.try(:title)) }
      .sort_by do |recording|
        label = recording.recordable&.try(:name) || recording.recordable&.try(:title)
        scenario_titles.index(label) || scenario_titles.length
      end
  end
end
