class HomeController < ApplicationController
  def index
    @workspace = Workspace.first
    @root_recording = RecordingStudio::Recording.unscoped.find_by(
      recordable: @workspace,
      parent_recording_id: nil
    )
    @page_recordings = RecordingStudio::Recording.unscoped
      .where(root_recording_id: @root_recording&.id)
      .where(recordable_type: "Page")
      .where(trashed_at: nil)
      .includes(:recordable)
  end
end
