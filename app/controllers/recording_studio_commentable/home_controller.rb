# frozen_string_literal: true

module RecordingStudioCommentable
  class HomeController < ApplicationController
    before_action :require_actor!

    PAGE_SIZE = 12

    def index
      @external_back_path = scenarios_target_path

      all_entries = visible_comment_entries
      @page = current_page
      @comment_entries = paginated_entries(all_entries)
      @next_page = next_page_for(all_entries)

      render partial: "comments_page", locals: comments_page_locals, layout: false if turbo_frame_request?
    end

    private

    def comments_page_locals
      {
        comment_entries: @comment_entries,
        page: @page,
        next_page: @next_page
      }
    end

    def current_page
      page_number = params[:page].to_i
      page_number.positive? ? page_number : 1
    end

    def paginated_entries(entries)
      entries.slice(page_offset, PAGE_SIZE) || []
    end

    def next_page_for(entries)
      entries.size > page_offset + PAGE_SIZE ? @page + 1 : nil
    end

    def page_offset
      (@page - 1) * PAGE_SIZE
    end

    def visible_comment_entries
      top_level_comments = visible_top_level_comment_recordings
      replies_by_parent = load_replies(top_level_comments)

      top_level_comments.filter_map do |comment_recording|
        parent_recording = root_recording_for(comment_recording.parent_recording)
        next if workspace_recording?(parent_recording)

        accessible = authorized_to_view?(parent_recording)

        {
          comment_recording: comment_recording,
          parent_recording: parent_recording,
          parent_title: recordable_display_title(parent_recording),
          accessible: accessible,
          replies: replies_by_parent.fetch(comment_recording.id, [])
        }
      end
    end

    def visible_top_level_comment_recordings
      return [] unless defined?(RecordingStudio::Recording)

      comment_recordings = RecordingStudio::Recording
                           .where(recordable_type: "RecordingStudioCommentable::Comment")
                           .where(trashed_at: nil)
                           .includes(:recordable, :parent_recording)
                           .order(created_at: :desc)

      comment_recordings.reject do |comment_recording|
        comment_recording?(comment_recording.parent_recording)
      end
    end

    def load_replies(top_level_comments)
      return {} unless defined?(RecordingStudio::Recording)
      return {} if top_level_comments.empty?

      RecordingStudio::Recording
        .where(parent_recording_id: top_level_comments.map(&:id))
        .where(recordable_type: "RecordingStudioCommentable::Comment")
        .where(trashed_at: nil)
        .order(created_at: :asc)
        .includes(:recordable)
        .group_by(&:parent_recording_id)
    end

    def comment_recording?(recording)
      return false unless recording

      recording.recordable_type == "RecordingStudioCommentable::Comment"
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

    def root_recording_for(recording)
      return recording unless recording.respond_to?(:root_recording)

      recording.root_recording || recording
    end

    def workspace_recording?(recording)
      return false unless recording

      recording.recordable_type == "Workspace"
    end

    def scenarios_target_path
      return main_app.scenarios_path(anchor: "comment-scenarios") if main_app.respond_to?(:scenarios_path)

      main_app.root_path
    end
  end
end
