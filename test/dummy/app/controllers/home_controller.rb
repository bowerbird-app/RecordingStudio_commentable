class HomeController < ApplicationController
  before_action :load_workspace_context, only: %i[index scenarios services recordings recording gem_routes]
  before_action :load_scenario_recordings, only: %i[index scenarios]
  before_action :load_service_catalog, only: :services
  before_action :load_recording_catalog, only: :recordings
  before_action :load_recording_detail, only: :recording
  before_action :load_gem_route_catalog, only: :gem_routes

  def index
  end

  def scenarios
  end

  def services
  end

  def recordings
  end

  def recording
  end

  def gem_routes
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

  def load_gem_route_catalog
    @gem_route_groups = [
      {
        title: "Mounted engine routes",
        subtitle: "Routes exposed under /commentable by the mounted RecordingStudioCommentable engine.",
        routes: route_catalog_for(
          RecordingStudioCommentable::Engine.routes,
          path_prefix: "/commentable"
        )
      },
      {
        title: "Dummy app routes",
        subtitle: "Host-app routes that still dispatch into RecordingStudioCommentable controllers.",
        routes: route_catalog_for(
          Rails.application.routes,
          controller_prefix: "recording_studio_commentable/"
        )
      }
    ]
  end

  def load_recording_catalog
    @recordings = RecordingStudio::Recording.unscoped
      .where(recordable_type: ["Folder", "Page"])
      .where(parent_recording_id: nil)
      .where(trashed_at: nil)
      .includes(:recordable)
      .order(created_at: :asc)
    @recording_entries = @recordings.map do |recording|
      {
        recording: recording,
        title: recordable_display_title(recording.recordable, missing: "Missing recordable")
      }
    end
  end

  def route_catalog_for(route_set, path_prefix: nil, controller_prefix: nil)
    route_set.routes.filter_map do |route|
      controller = route.defaults[:controller].to_s
      next if controller.blank?
      next if controller_prefix && !controller.start_with?(controller_prefix)

      {
        name: route.name.presence || "(none)",
        verb: normalized_route_verb(route),
        path: normalized_route_path(route, path_prefix: path_prefix),
        controller: controller,
        action: route.defaults[:action].to_s
      }
    end.sort_by { |entry| [entry[:path], entry[:verb], entry[:name]] }
  end

  def normalized_route_verb(route)
    route.verb.to_s.delete("^").delete("$").split("|").join(", ")
  end

  def normalized_route_path(route, path_prefix: nil)
    path = route.path.spec.to_s.delete_suffix("(.:format)")
    return path if path_prefix.blank? || path.start_with?(path_prefix)

    "#{path_prefix}#{path}"
  end

  def load_recording_detail
    @recording = find_recording(params[:id])
    if @recording
      @recording_snapshot = recording_snapshot(@recording)
      @recording_children = structure_child_recordings(@recording)
      @recording_events = structure_events(@recording)
      return
    end

    redirect_to recordings_browser_path, alert: "Recording not found."
    nil
  end

  def find_recording(id)
    return unless defined?(RecordingStudio::Recording)

    RecordingStudio::Recording.unscoped.includes(:recordable).find_by(id: id)
  end

  def recording_snapshot(recording)
    recordable = recording.respond_to?(:recordable) ? recording.recordable : nil

    {
      recording: recording,
      title: recordable_display_title(recordable, missing: "Missing recordable"),
      recording_details: recording_only_details(recording),
      recordable_title: recordable_display_title(recordable, missing: "Missing recordable"),
      recordable_details: recordable_snapshot_details(recordable)
    }
  end

  def structure_child_recordings(recording)
    return [] unless defined?(RecordingStudio::Recording)

    RecordingStudio::Recording.unscoped
      .where(parent_recording: recording)
      .where(trashed_at: nil)
      .order(created_at: :asc)
      .includes(:recordable)
      .map { |child_recording| recording_snapshot(child_recording) }
  end

  def structure_events(recording)
    return [] unless defined?(RecordingStudio::Event)

    child_recording_ids = RecordingStudio::Recording.unscoped
      .where(parent_recording: recording)
      .pluck(:id)
    recording_ids = [recording.id] + child_recording_ids

    RecordingStudio::Event
      .where(recording_id: recording_ids)
      .order(created_at: :asc)
      .map do |event|
        event_recordable = event.respond_to?(:recordable) ? event.recordable : nil

        {
          event: event,
          title: event.action.to_s.humanize,
          details: event_snapshot_details(event),
          recordable_title: recordable_display_title(event_recordable, missing: "Missing recordable"),
          recordable_details: event_recordable_snapshot_details(event, event_recordable)
        }
      end
  end

  def recording_only_details(recording)
    details = []
    details << ["Recording", recording.id]
    details << ["Recordable type", recording.recordable_type]
    details << ["Recordable id", recording.recordable_id]
    details << ["Parent recording", recording.parent_recording_id] if recording.parent_recording_id.present?
    details << ["Root recording", recording.root_recording_id] if recording.root_recording_id.present?
    details << ["Created", recording.created_at]
    details << ["Trashed", recording.trashed_at] if recording.trashed_at.present?
    details
  end

  def recordable_snapshot_details(recordable)
    return [["Recordable", "Missing"]] unless recordable

    details = []
    details << ["Class", recordable.class.name]
    details << ["Id", recordable.id] if recordable.respond_to?(:id)
    details << ["Model title", recordable.title] if recordable.respond_to?(:title) && recordable.title.present?
    details << ["Model name", recordable.name] if recordable.respond_to?(:name) && recordable.name.present?
    details << ["Body", recordable.body] if recordable.respond_to?(:body) && recordable.body.present?
    if recordable.respond_to?(:author_display_name) && recordable.author_display_name.present?
      details << ["Author", recordable.author_display_name]
    end
    details << ["Role", recordable.role] if recordable.respond_to?(:role) && recordable.role.present?
    if recordable.respond_to?(:minimum_role) && recordable.minimum_role.present?
      details << ["Minimum role", recordable.minimum_role]
    end
    details
  end

  def event_snapshot_details(event)
    details = []
    details << ["Event", event.id]
    details << ["Action", event.action]
    details << ["Recording", event.recording_id]
    if event.actor.present?
      details << ["Actor", event.actor.respond_to?(:display_name) ? event.actor.display_name : event.actor.to_s]
    end
    details << ["Occurred", event.occurred_at]
    details
  end

  def event_recordable_snapshot_details(event, recordable)
    details = []
    details << ["Recordable type", event.recordable_type]
    details << ["Recordable id", event.recordable_id]
    details << ["Previous recordable type", event.previous_recordable_type] if event.previous_recordable_type.present?
    details << ["Previous recordable id", event.previous_recordable_id] if event.previous_recordable_id.present?
    details.concat(recordable_snapshot_details(recordable)) if recordable
    details
  end
end
