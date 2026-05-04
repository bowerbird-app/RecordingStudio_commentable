require "ostruct"

class HomeController < ApplicationController
  before_action :load_workspace_context, only: %i[index scenarios helpers recordings recording gem_routes]
  before_action :load_scenario_recordings, only: %i[index scenarios]
  before_action :load_helper_catalog, only: :helpers
  before_action :load_recording_catalog, only: :recordings
  before_action :load_recording_detail, only: :recording
  before_action :load_gem_route_catalog, only: :gem_routes

  def index
  end

  def scenarios
  end

  def helpers
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

  def load_helper_catalog
    @helper_catalog = [
      {
        title: "recordable_display_title",
        source: "RecordingStudioCommentable::RecordableDisplayHelper",
        summary: "Resolves a readable label for a recordable or recording wrapper using configured mappings and fallback attributes.",
        signature: 'recordable_display_title(recordable_or_recording, missing: "Unknown item")',
        examples: [
          {
            label: "Recordable title fallback",
            input: 'recordable_display_title(OpenStruct.new(title: "Launch plan"))',
            output: recordable_display_title(OpenStruct.new(title: "Launch plan"))
          },
          {
            label: "Missing recordable fallback",
            input: 'recordable_display_title(nil, missing: "Missing recordable")',
            output: recordable_display_title(nil, missing: "Missing recordable")
          }
        ]
      },
      {
        title: "truncate_comment_body",
        source: "RecordingStudioCommentable::CommentBodyHelper",
        summary: "Strips rich text markup and truncates long comment bodies at a word boundary for previews.",
        signature: 'truncate_comment_body(comment_or_body, length: 280, omission: "...")',
        examples: [
          {
            label: "HTML preview",
            input: 'truncate_comment_body("<p>This is a long <strong>comment</strong> body for previews.</p>", length: 26)',
            output: truncate_comment_body("<p>This is a long <strong>comment</strong> body for previews.</p>", length: 26)
          },
          {
            label: "Comment-like object",
            input: 'truncate_comment_body(OpenStruct.new(body: "Short comment"))',
            output: truncate_comment_body(OpenStruct.new(body: "Short comment"))
          }
        ]
      },
      {
        title: "current_recording_studio_actor",
        source: "ApplicationController helper_method",
        summary: "Exposes the current signed-in actor to the dummy app and commentable views.",
        signature: "current_recording_studio_actor()",
        examples: [
          {
            label: "Current actor email",
            input: "current_recording_studio_actor&.email",
            output: current_recording_studio_actor&.email.to_s
          }
        ]
      }
    ]

    @helper_notes = [
      "RecordableDisplayHelper is included in both the dummy app controller and the engine controller.",
      "CommentBodyHelper is exposed in the dummy app so helper previews match the commentable pages.",
      "Each helper is available to ERB templates through helper_method wiring on the controller layer.",
      "These examples are intended as copyable reference snippets for future dummy pages and comment UI states."
    ]

    @service_catalog = [
      {
        title: "CreateComment.call",
        source: "RecordingStudioCommentable::Services::CreateComment",
        summary: "Creates a new comment under a parent recording and returns a BaseService::Result.",
        signature: 'RecordingStudioCommentable::Services::CreateComment.call(parent_recording:, body:, author: nil)',
        examples: [
          {
            label: "Create a comment",
            input: 'RecordingStudioCommentable::Services::CreateComment.call(parent_recording: recording, body: "Great work", author: current_user)',
            output: "Returns a Result with success?, value, error, and errors"
          }
        ]
      },
      {
        title: "UpdateComment.call",
        source: "RecordingStudioCommentable::Services::UpdateComment",
        summary: "Revises an existing comment body while preserving RecordingStudio history when available.",
        signature: 'RecordingStudioCommentable::Services::UpdateComment.call(comment_recording:, root_recording:, body:, actor: nil)',
        examples: [
          {
            label: "Update a comment",
            input: 'RecordingStudioCommentable::Services::UpdateComment.call(comment_recording: comment_recording, root_recording: root_recording, body: "Updated text", actor: current_user)',
            output: "Returns a Result with the updated comment as value on success"
          }
        ]
      },
      {
        title: "DestroyComment.call",
        source: "RecordingStudioCommentable::Services::DestroyComment",
        summary: "Trashes or destroys a comment recording and returns a BaseService::Result.",
        signature: 'RecordingStudioCommentable::Services::DestroyComment.call(comment_recording:, root_recording:, actor: nil)',
        examples: [
          {
            label: "Remove a comment",
            input: 'RecordingStudioCommentable::Services::DestroyComment.call(comment_recording: comment_recording, root_recording: root_recording, actor: current_user)',
            output: "Returns a Result with the removed comment or recording on success"
          }
        ]
      },
      {
        title: "BaseService::Result",
        source: "RecordingStudioCommentable::Services::BaseService::Result",
        summary: "Common response object returned by the public service entrypoints.",
        signature: "result.success? / result.failure? / result.value / result.error / result.errors / result.on_success / result.on_failure / result.value!",
        examples: [
          {
            label: "Handle success or failure",
            input: "result.on_success { |value| ... }.on_failure { |error, errors| ... }",
            output: "Allows chaining success and failure handlers on the result object"
          }
        ]
      }
    ]

    @host_api_catalog = [
      {
        title: "RecordingStudioCommentable.configure",
        source: "RecordingStudioCommentable module",
        summary: "Primary host-app entrypoint for configuring the addon.",
        signature: "RecordingStudioCommentable.configure do |config| ... end",
        examples: [
          {
            label: "Configure layout and rich text",
            input: 'RecordingStudioCommentable.configure do |config|\n  config.layout = "flat_pack_sidebar"\n  config.use_recording_studio_trashable_for_destroy = true\n  config.rich_text_comments = :selection\nend',
            output: "Updates the shared Configuration object used by the engine"
          }
        ]
      },
      {
        title: "RecordingStudioCommentable.configuration",
        source: "RecordingStudioCommentable module",
        summary: "Returns the normalized configuration object for reads or advanced host setup.",
        signature: "RecordingStudioCommentable.configuration",
        examples: [
          {
            label: "Read merged config",
            input: "RecordingStudioCommentable.configuration.rich_text_comments",
            output: RecordingStudioCommentable.configuration.rich_text_comments.inspect
          }
        ]
      },
      {
        title: "Commentable concern",
        source: "RecordingStudioCommentable::Commentable",
        summary: "Include this concern in a host model to mark it as commentable.",
        signature: "include RecordingStudioCommentable::Commentable",
        examples: [
          {
            label: "Opt a model into comments",
            input: 'class Page < ApplicationRecord\n  include RecordingStudioCommentable::Commentable\nend',
            output: "Adds class- and instance-level commentable? checks"
          }
        ]
      },
      {
        title: "Comment author methods",
        source: "RecordingStudioCommentable::Comment",
        summary: "Comment records expose derived author metadata for rendering names and avatars in the feed.",
        signature: "comment.author_display_name / comment.author_avatar_url",
        examples: [
          {
            label: "Resolve an author avatar",
            input: 'RecordingStudioCommentable.configure do |config|\n  config.author_avatar_attributes = { "User" => :avatar_url }\nend\ncomment.author_avatar_url',
            output: "Returns the configured avatar URL for the comment author, or nil when unavailable"
          }
        ]
      },
      {
        title: "Hooks API",
        source: "RecordingStudioCommentable::Hooks",
        summary: "Host hooks for initialization, service instrumentation, and model/controller extensions.",
        signature: "config.hooks.before_initialize / after_initialize / on_configuration / before_service / after_service / around_service / extend_model / extend_controller",
        examples: [
          {
            label: "Instrument services",
            input: 'RecordingStudioCommentable.configure do |config|\n  config.hooks.after_service do |service_class, result|\n    Rails.logger.info("#{service_class.name}: #{result.success?}")\n  end\nend',
            output: "Registers a host hook against the shared hooks registry"
          }
        ]
      },
      {
        title: "Mounted routes",
        source: "RecordingStudioCommentable::Engine",
        summary: "Mounted engine routes provide the browser surface after installation.",
        signature: 'mount RecordingStudioCommentable::Engine, at: "/commentable"',
        examples: [
          {
            label: "Open the addon home",
            input: 'recording_studio_commentable.root_path or /commentable',
            output: "Navigates to the installed addon UI"
          }
        ]
      }
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
