class HomeController < ApplicationController
  before_action :load_workspace_context, only: %i[index scenarios services]
  before_action :load_scenario_recordings, only: %i[index scenarios]
  before_action :load_service_catalog, only: :services

  def index
  end

  def scenarios
    @new_comment = RecordingStudioCommentable::Comment.new
  end

  def services
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

  def load_service_catalog
    @service_catalog = [
      {
        title: "CreateComment",
        class_name: "RecordingStudioCommentable::Services::CreateComment",
        summary: "Creates a new comment under a parent recording.",
        inputs: ["parent_recording", "body", "author"],
        behavior: [
          "Rejects blank bodies.",
          "Builds a RecordingStudioCommentable::Comment instance.",
          "Records the comment under the parent recording when RecordingStudio is available.",
          "Falls back to saving the comment directly in standalone/test mode."
        ]
      },
      {
        title: "UpdateComment",
        class_name: "RecordingStudioCommentable::Services::UpdateComment",
        summary: "Revises an existing comment while preserving RecordingStudio history.",
        inputs: ["comment_recording", "root_recording", "body", "actor"],
        behavior: [
          "Rejects blank bodies.",
          "Uses RecordingStudio revise when the root recording supports it.",
          "Updates the comment record directly when RecordingStudio is unavailable.",
          "Returns the updated comment via the shared Result object."
        ]
      },
      {
        title: "DestroyComment",
        class_name: "RecordingStudioCommentable::Services::DestroyComment",
        summary: "Removes a comment from the active feed without hard-deleting its history.",
        inputs: ["comment_recording", "root_recording", "actor"],
        behavior: [
          "Uses RecordingStudio trash when available.",
          "Soft-deletes at the recording layer so history is preserved.",
          "Falls back to destroying the comment record directly outside RecordingStudio.",
          "Returns the affected comment recording via the shared Result object."
        ]
      }
    ]

    @service_features = [
      "All service objects inherit from RecordingStudioCommentable::Services::BaseService.",
      "Each service exposes a .call entry point and returns a Result with success?, value, error, and errors.",
      "Before, after, and around hooks run through RecordingStudioCommentable::Hooks when configured.",
      "Errors are normalized into failed Result objects instead of leaking exceptions into controllers."
    ]
  end
end
