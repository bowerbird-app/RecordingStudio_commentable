# frozen_string_literal: true

module RecordingStudioCommentable
  class CommentsController < ApplicationController
    before_action :require_actor!
    before_action :load_parent_recording
    before_action :require_commentable!
    before_action :authorize_view!, only: %i[index]
    before_action :authorize_create!, only: %i[new create]
    before_action :load_comment_recording, only: %i[edit update destroy]
    before_action :authorize_edit!, only: %i[edit update destroy]

    def index
      @comments = chronological_comments
      @structure_parent = recording_snapshot(@parent_recording)
      @structure_children = structure_child_recordings
      @structure_events = structure_events
    end

    def new
      @comment = Comment.new
    end

    def create
      result = Services::CreateComment.call(
        parent_recording: @parent_recording,
        body: comment_params[:body],
        author: current_recording_studio_actor
      )

      if result.success?
        redirect_to redirect_target(recording_comments_path(@parent_recording)),
                    notice: "Comment added."
      elsif return_to_path
        redirect_to redirect_target(recording_comments_path(@parent_recording)),
                    alert: result.errors.presence&.join(", ") || result.error || "Comment could not be added."
      else
        @comment = Comment.new(body: comment_params[:body])
        @comment.errors.add(:base, result.error) if result.error
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @comment = @comment_recording.respond_to?(:recordable) ? @comment_recording.recordable : @comment_recording
    end

    def update
      root = root_recording_for(@parent_recording)
      result = Services::UpdateComment.call(
        comment_recording: @comment_recording,
        root_recording: root,
        body: comment_params[:body],
        actor: current_recording_studio_actor
      )

      if result.success?
        redirect_to redirect_target(recording_comments_path(@parent_recording)),
                    notice: "Comment updated."
      else
        @comment = @comment_recording.respond_to?(:recordable) ? @comment_recording.recordable : @comment_recording
        @comment.errors.add(:base, result.error) if result.error
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      root = root_recording_for(@parent_recording)
      Services::DestroyComment.call(
        comment_recording: @comment_recording,
        root_recording: root,
        actor: current_recording_studio_actor
      )

      redirect_to redirect_target(recording_comments_path(@parent_recording)),
                  notice: "Comment deleted."
    end

    private

    def return_to_path
      path = params[:return_to].to_s
      return if path.blank? || !path.start_with?("/")

      path
    end

    def redirect_target(default)
      return_to_path || default
    end

    # ------------------------------------------------------------------ #
    # Finders
    # ------------------------------------------------------------------ #

    def load_parent_recording
      @parent_recording = find_recording(params[:recording_id])
      return if @parent_recording

      redirect_to(redirect_target(main_app.root_path), alert: "Recording not found.")
    end

    def load_comment_recording
      @comment_recording = find_recording(params[:id])
      return if @comment_recording

      redirect_to(redirect_target(recording_comments_path(@parent_recording)), alert: "Comment not found.")
    end

    # ------------------------------------------------------------------ #
    # Access control
    # ------------------------------------------------------------------ #

    def require_commentable!
      recordable = @parent_recording.respond_to?(:recordable) ? @parent_recording.recordable : nil
      return if recordable&.class&.include?(RecordingStudioCommentable::Commentable)

      redirect_to(redirect_target(main_app.root_path), alert: "Comments are not enabled for this resource.")
    end

    def authorize_view!
      return if authorized?(:view)

      redirect_to(redirect_target(main_app.root_path), alert: "You are not allowed to view comments here.")
    end

    def authorize_create!
      return if authorized?(:edit)

      redirect_to(redirect_target(recording_comments_path(@parent_recording)),
                  alert: "You are not allowed to post comments here.")
    end

    def authorize_edit!
      actor = current_recording_studio_actor
      comment_recordable = @comment_recording.respond_to?(:recordable) ? @comment_recording.recordable : nil

      # Allow comment authors to edit their own comments
      return if comment_recordable.respond_to?(:author) && comment_recordable.author == actor

      return if authorized?(:manage)

      redirect_to(redirect_target(recording_comments_path(@parent_recording)),
                  alert: "You are not allowed to edit this comment.")
    end

    def authorized?(role)
      return true unless defined?(RecordingStudioAccessible)

      RecordingStudioAccessible.authorized?(
        actor: current_recording_studio_actor,
        recording: @parent_recording,
        role: role
      )
    end

    # ------------------------------------------------------------------ #
    # Helpers
    # ------------------------------------------------------------------ #

    def chronological_comments
      return [] unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording
        .where(parent_recording: @parent_recording)
        .where(recordable_type: "RecordingStudioCommentable::Comment")
        .where(trashed_at: nil)
        .order(created_at: :asc)
        .includes(:recordable)
    end

    def structure_child_recordings
      return [] unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording.unscoped
                                .where(parent_recording: @parent_recording)
                                .where(trashed_at: nil)
                                .order(created_at: :asc)
                                .includes(:recordable)
                                .map { |recording| recording_snapshot(recording) }
    end

    def structure_events
      return [] unless defined?(RecordingStudio::Event)

      recording_ids = [@parent_recording.id] + @structure_children.map { |child| child[:recording].id }

      RecordingStudio::Event
        .where(recording_id: recording_ids)
        .order(created_at: :asc)
        .map do |event|
          event_recordable = event.respond_to?(:recordable) ? event.recordable : nil

          {
            event: event,
            title: event.action.to_s.humanize,
            details: event_snapshot_details(event),
            recordable_title: recordable_title(event_recordable),
            recordable_details: event_recordable_snapshot_details(event, event_recordable)
          }
        end
    end

    def recording_snapshot(recording)
      recordable = recording.respond_to?(:recordable) ? recording.recordable : nil

      {
        recording: recording,
        title: recordable_title(recordable),
        recording_details: recording_only_details(recording),
        recordable_title: recordable_title(recordable),
        recordable_details: recordable_snapshot_details(recordable)
      }
    end

    def recordable_title(recordable)
      return "Missing recordable" unless recordable

      recordable.try(:title) || recordable.try(:name) || recordable.class.name
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
      return [%w[Recordable Missing]] unless recordable

      details = []
      details << ["Class", recordable.class.name]
      details << ["Id", recordable.id] if recordable.respond_to?(:id)
      details << ["Model title", recordable.title] if recordable.respond_to?(:title) && recordable.title.present?
      details << ["Model name", recordable.name] if recordable.respond_to?(:name) && recordable.name.present?
      details << ["Body", recordable.body] if recordable.respond_to?(:body) && recordable.body.present?
      if recordable.respond_to?(:author_display_name) && recordable.author_display_name.present?
        details << ["Author",
                    recordable.author_display_name]
      end
      details << ["Role", recordable.role] if recordable.respond_to?(:role) && recordable.role.present?
      if recordable.respond_to?(:minimum_role) && recordable.minimum_role.present?
        details << ["Minimum role",
                    recordable.minimum_role]
      end
      details
    end

    def event_snapshot_details(event)
      details = []
      details << ["Event", event.id]
      details << ["Action", event.action]
      details << ["Recording", event.recording_id]
      if event.actor.present?
        details << ["Actor",
                    event.actor.respond_to?(:display_name) ? event.actor.display_name : event.actor.to_s]
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

    def root_recording_for(recording)
      return recording unless recording.respond_to?(:root_recording)

      recording.root_recording || recording
    end

    def find_recording(id)
      return unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording.find_by(id: id)
    end

    def comment_params
      params.require(:comment).permit(:body)
    end
  end
end
