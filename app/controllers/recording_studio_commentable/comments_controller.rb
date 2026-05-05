# frozen_string_literal: true

require "uri"

module RecordingStudioCommentable
  class CommentsController < ApplicationController
    before_action :require_actor!
    before_action :load_parent_recording, except: %i[reply create_reply]
    before_action :load_reply_target_comment_recording, only: %i[reply create_reply]
    before_action :load_reply_parent_recording, only: %i[reply create_reply]
    before_action :require_commentable!
    before_action :authorize_view!, only: %i[index all reply]
    before_action :authorize_create!, only: %i[new create reply create_reply]
    before_action :load_comment_recording, only: %i[edit update destroy]
    before_action :authorize_edit!, only: %i[edit update destroy]
    before_action :prepare_page_context

    def index
      @show_comments = summary_show_comments_request?
      @comments_count = comment_count
      return unless @show_comments

      @comment = Comment.new
      @comments = comments_relation.to_a
      @replies = load_replies(@comments)
    end

    def all
      @comment = Comment.new
      @comments_count = comment_count
    end

    def new
      @comment = Comment.new
      @parent_comment_recording = find_parent_comment_recording
      @composer_title = "Add comment"
      @composer_url = main_app.recording_comments_path(@parent_recording, return_to_options)
    end

    def reply
      @comment = Comment.new
      @parent_comment_recording = @reply_target_comment_recording
      @comments_count = comment_count
      @composer_title = "Reply"
      @composer_subtitle = truncate_comment_body(comment_from(@reply_target_comment_recording), length: 120)
      @composer_url = recording_studio_commentable.reply_comment_path(@reply_target_comment_recording, return_to_options)

      render :new
    end

    def create
      effective_parent = find_parent_comment_recording || @parent_recording

      result = Services::CreateComment.call(
        parent_recording: effective_parent,
        body: comment_params[:body],
        author: current_recording_studio_actor
      )

      if result.success?
        redirect_to post_create_redirect_path,
                    notice: "Comment added."
      else
        @comment = Comment.new(body: comment_params[:body])
        @comment.errors.add(:base, result.error) if result.error
        if inline_composer_request? && summary_show_comments_request?
          @show_comments = true
          @comments = comments_relation.to_a
          @comments_count = comment_count
          @replies = load_replies(@comments)
          render :index, status: :unprocessable_entity
        elsif inline_composer_request?
          @comments_count = comment_count
          render :all, status: :unprocessable_entity
        else
          @composer_title = "Add comment"
          @composer_url = main_app.recording_comments_path(@parent_recording, return_to_options)
          render :new, status: :unprocessable_entity
        end
      end
    end

    def create_reply
      result = Services::CreateComment.call(
        parent_recording: @reply_target_comment_recording,
        body: comment_params[:body],
        author: current_recording_studio_actor
      )

      if result.success?
        redirect_to post_reply_redirect_path,
                    notice: "Comment added."
      else
        @comment = Comment.new(body: comment_params[:body])
        @comment.errors.add(:base, result.error) if result.error
        @parent_comment_recording = @reply_target_comment_recording
        @comments_count = comment_count
        @composer_title = "Reply"
        @composer_subtitle = truncate_comment_body(comment_from(@reply_target_comment_recording), length: 120)
        @composer_url = recording_studio_commentable.reply_comment_path(@reply_target_comment_recording, return_to_options)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @comment = comment_from(@comment_recording)
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
        redirect_to comments_collection_path,
                    notice: "Comment updated."
      else
        @comment = comment_from(@comment_recording)
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

      redirect_to commentable_home_referer_path || comments_collection_path,
                  notice: "Comment deleted."
    end

    private

    def return_to_path
      @return_to_path ||= normalize_relative_path(params[:return_to].to_s)
    end

    # ------------------------------------------------------------------ #
    # Finders
    # ------------------------------------------------------------------ #

    def load_parent_recording
      @parent_recording = find_recording(params[:recording_id])
      return if @parent_recording

      redirect_to(return_to_path || main_app.root_path, alert: "Recording not found.")
    end

    def load_comment_recording
      @comment_recording = find_recording(params[:id])
      return if @comment_recording

      redirect_to(comments_collection_path, alert: "Comment not found.")
    end

    def load_reply_target_comment_recording
      @reply_target_comment_recording = find_recording(params[:id])
      return if valid_reply_target_comment_recording?(@reply_target_comment_recording)

      redirect_to(commentable_reply_fallback_path, alert: "Comment not found.")
    end

    def load_reply_parent_recording
      @parent_recording = root_recording_for(@reply_target_comment_recording.parent_recording)
      return if @parent_recording

      redirect_to(commentable_reply_fallback_path, alert: "Recording not found.")
    end

    def prepare_page_context
      return unless @parent_recording

      @page_recordable = @parent_recording.try(:recordable)
      @page_title = recordable_display_title(@page_recordable, missing: "Missing recordable")
      @page_body = @page_recordable.try(:body).presence
      @summary_path = summary_path
      @comments_collection_path = host_comments_collection_path
      @new_comment_path = host_new_comment_path
      @external_back_path = commentable_home_referer_path || external_return_to_path || main_app.root_path
      @back_button_onclick = external_return_to_path.present? ? nil : 'if (window.history.length > 1) { event.preventDefault(); window.history.back(); }'
      @can_create_comment = authorized?(:edit)
    end

    # ------------------------------------------------------------------ #
    # Access control
    # ------------------------------------------------------------------ #

    def require_commentable!
      recordable = @parent_recording.try(:recordable)
      return if recordable&.class&.include?(RecordingStudioCommentable::Commentable)

      redirect_to(return_to_path || main_app.root_path, alert: "Comments are not enabled for this resource.")
    end

    def authorize_view!
      return if authorized?(:view)

      redirect_to(return_to_path || main_app.root_path, alert: "You are not allowed to view comments here.")
    end

    def authorize_create!
      return if authorized?(:edit)

      redirect_to(summary_path,
                  alert: "You are not allowed to post comments here.")
    end

    def authorize_edit!
      actor = current_recording_studio_actor
      comment_recordable = @comment_recording.try(:recordable)

      # Allow comment authors to edit their own comments
      return if comment_recordable.respond_to?(:author) && comment_recordable.author == actor

      return if authorized?(:manage)

      redirect_to(comments_collection_path,
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

    def return_to_options
      return {} unless return_to_path

      { return_to: return_to_path }
    end

    def external_return_to_path
      @external_return_to_path ||= begin
        path = return_to_path

        while (next_path = nested_comment_return_to_path(path))
          path = next_path
        end

        path
      end
    end

    def nested_comment_return_to_path(path)
      return unless path.present? && comment_navigation_path?(path)

      uri = URI.parse(path)
      params = Rack::Utils.parse_nested_query(uri.query.to_s)
      normalize_relative_path(params["return_to"].to_s)
    rescue URI::InvalidURIError
      nil
    end

    def comment_navigation_path?(path)
      uri = URI.parse(path)

      [
        main_app.recording_comments_path(@parent_recording),
        main_app.all_recording_comments_path(@parent_recording),
        main_app.new_recording_comment_path(@parent_recording)
      ].include?(uri.path)
    rescue URI::InvalidURIError
      false
    end

    def normalize_relative_path(path)
      return if path.blank?

      uri = URI.parse(path)
      return if uri.host.present? || uri.path.nil? || !uri.path.start_with?("/")

      uri.query.present? ? "#{uri.path}?#{uri.query}" : uri.path
    rescue URI::InvalidURIError
      nil
    end

    def commentable_home_referer_path
      return unless request.referer.present?

      referer_uri = URI.parse(request.referer)
      normalized_home_paths = [root_path, root_path.chomp("/")].uniq
      return unless normalized_home_paths.include?(referer_uri.path)

      referer_uri.query.present? ? "#{referer_uri.path}?#{referer_uri.query}" : referer_uri.path
    rescue URI::InvalidURIError
      nil
    end

    def comments_collection_path
      @comments_collection_path || host_comments_collection_path
    end

    def expanded_summary_path
      summary_path(show_comments: true)
    end

    def summary_path(show_comments: false)
      main_app.recording_comments_path(
        @parent_recording,
        return_to_options.merge(show_comments ? { show_comments: true } : {})
      )
    end

    def host_comments_collection_path
      main_app.all_recording_comments_path(@parent_recording, return_to_options.merge(feed_query_options))
    end

    def host_new_comment_path
      main_app.new_recording_comment_path(@parent_recording, return_to_options)
    end

    def inline_composer_request?
      ActiveModel::Type::Boolean.new.cast(params[:inline_composer])
    end

    def summary_show_comments_request?
      ActiveModel::Type::Boolean.new.cast(params[:show_comments])
    end

    def post_create_redirect_path
      return expanded_summary_path if summary_show_comments_request?

      comments_collection_path
    end

    def post_reply_redirect_path
      return return_to_path if return_to_path

      recording_studio_commentable.root_path
    end

    def comments_relation
      @comments_relation ||= chronological_comments
    end

    def comment_count
      @comment_count ||= RecordingStudioCommentable::CommentCount.for_recording(@parent_recording)
    end

    def feed_query_options
      options = {}
      loading = params[:loading].to_s
      options[:loading] = loading if %w[infinite load_more].include?(loading)

      page_size = params[:page_size].to_i
      options[:page_size] = page_size if page_size.positive?
      options
    end

    def chronological_comments
      return [] unless defined?(RecordingStudio::Recording)

      RecordingStudio::Recording
        .where(parent_recording: @parent_recording)
        .where(recordable_type: "RecordingStudioCommentable::Comment")
        .where(trashed_at: nil)
        .order(created_at: :asc)
        .includes(:recordable)
    end

    # Loads replies for a list of top-level comment recordings.
    # Returns a Hash of { recording_id => [reply_recordings] }.
    def load_replies(top_level_recordings)
      return {} unless defined?(RecordingStudio::Recording)
      return {} if top_level_recordings.empty?

      ids = top_level_recordings.map(&:id)

      RecordingStudio::Recording
        .where(parent_recording_id: ids)
        .where(recordable_type: "RecordingStudioCommentable::Comment")
        .where(trashed_at: nil)
        .order(created_at: :asc)
        .includes(:recordable)
        .group_by(&:parent_recording_id)
    end

    # Resolves the parent comment recording from params[:parent_comment_id].
    # Returns nil when the param is absent or the recording fails security checks.
    # Security: the recording must be a non-trashed comment that is a direct child
    # of the current page recording, preventing cross-thread reply injection.
    def find_parent_comment_recording
      return unless params[:parent_comment_id].present?

      recording = find_recording(params[:parent_comment_id])
      return unless recording
      return unless recording.parent_recording_id == @parent_recording.id
      return unless recording.recordable_type == "RecordingStudioCommentable::Comment"
      return if recording.trashed_at.present?

      recording
    end

    def valid_reply_target_comment_recording?(recording)
      recording.present? &&
        recording.recordable_type == "RecordingStudioCommentable::Comment" &&
        recording.trashed_at.blank?
    end

    def commentable_reply_fallback_path
      return return_to_path if return_to_path

      recording_studio_commentable.root_path
    end

    def comment_from(comment_recording)
      comment_recording.try(:recordable) || comment_recording
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
