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
        redirect_to recording_comments_path(@parent_recording),
                    notice: "Comment added."
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
        redirect_to recording_comments_path(@parent_recording),
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

      redirect_to recording_comments_path(@parent_recording),
                  notice: "Comment deleted."
    end

    private

    # ------------------------------------------------------------------ #
    # Finders
    # ------------------------------------------------------------------ #

    def load_parent_recording
      @parent_recording = find_recording(params[:recording_id])
      return if @parent_recording

      redirect_to(main_app.root_path, alert: "Recording not found.")
    end

    def load_comment_recording
      @comment_recording = find_recording(params[:id])
      return if @comment_recording

      redirect_to(recording_comments_path(@parent_recording), alert: "Comment not found.")
    end

    # ------------------------------------------------------------------ #
    # Access control
    # ------------------------------------------------------------------ #

    def require_commentable!
      recordable = @parent_recording.respond_to?(:recordable) ? @parent_recording.recordable : nil
      return if recordable&.class&.include?(RecordingStudioCommentable::Commentable)

      redirect_to(main_app.root_path, alert: "Comments are not enabled for this resource.")
    end

    def authorize_view!
      return if authorized?(:view)

      redirect_to(main_app.root_path, alert: "You are not allowed to view comments here.")
    end

    def authorize_create!
      return if authorized?(:edit)

      redirect_to(recording_comments_path(@parent_recording), alert: "You are not allowed to post comments here.")
    end

    def authorize_edit!
      actor = current_recording_studio_actor
      comment_recordable = @comment_recording.respond_to?(:recordable) ? @comment_recording.recordable : nil

      # Allow comment authors to edit their own comments
      if comment_recordable.respond_to?(:author) && comment_recordable.author == actor
        return
      end

      return if authorized?(:manage)

      redirect_to(recording_comments_path(@parent_recording), alert: "You are not allowed to edit this comment.")
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
