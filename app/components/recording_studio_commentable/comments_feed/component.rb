# frozen_string_literal: true

module RecordingStudioCommentable
  module CommentsFeed
    class Component < ViewComponent::Base
      COMMENT_RECORDABLE_TYPE = "RecordingStudioCommentable::Comment"
      LOADING_MODES = %i[all infinite load_more].freeze
      DEFAULT_PAGE_SIZE = 20
      DEFAULT_REPLY_BUTTON_OPTIONS = {
        text: "Reply",
        style: :ghost,
        size: :sm,
        data: { turbo_frame: "_top" }
      }.freeze

      def initialize(recording:, mode: :all, page_size: DEFAULT_PAGE_SIZE, include_composer: false, return_to: nil,
                     comment: nil, can_create_comment: nil, reply_action: nil)
        super()
        @recording = recording
        @requested_mode = mode
        @requested_page_size = page_size
        @include_composer = include_composer
        @return_to = return_to
        @comment = comment
        @can_create_comment = can_create_comment
        @reply_action = reply_action
      end

      def loading_mode
        @loading_mode ||= begin
          candidate = @requested_mode.presence || helpers.params[:loading]
          normalized = candidate.to_s.presence&.underscore&.to_sym
          LOADING_MODES.include?(normalized) ? normalized : :all
        end
      end

      def page_size
        @page_size ||= begin
          value = @requested_page_size.presence || helpers.params[:page_size]
          size = value.to_i
          size.positive? ? size : DEFAULT_PAGE_SIZE
        end
      end

      def include_composer?
        @include_composer
      end

      def can_create_comment?
        return false unless include_composer?
        return @can_create_comment unless @can_create_comment.nil?

        authorized_to_edit?
      end

      def composer_comment
        @comment || RecordingStudioCommentable::Comment.new
      end

      def composer_url
        args = { inline_composer: true }.merge(return_to_options).merge(feed_query_options)
        helpers.main_app.recording_comments_path(recording, args)
      end

      def comments_count
        @comments_count ||= RecordingStudioCommentable::CommentCount.for_recording(recording)
      end

      def paginated?
        loading_mode != :all
      end

      def render_page_only?
        paginated? && turbo_frame_request?
      end

      def comments_page_locals
        {
          feed: self,
          comments: current_page_comments,
          replies: replies_for_current_page,
          page: current_page,
          next_page: next_page
        }
      end

      def current_page_comments
        @current_page_comments ||= begin
          scope = top_level_comments_relation
          if paginated?
            scope = if scope.respond_to?(:limit)
                      scope.limit(page_size).offset((current_page - 1) * page_size)
                    else
                      Array(scope).slice((current_page - 1) * page_size, page_size) || []
                    end
          end
          scope.to_a
        end
      end

      def replies_for_current_page
        @replies_for_current_page ||= load_replies(current_page_comments)
      end

      def current_page
        page = helpers.params[:page].to_i
        page.positive? ? page : 1
      end

      def next_page
        return unless paginated?
        return unless top_level_comments_count > current_page * page_size

        current_page + 1
      end

      def page_frame_id(page)
        "comments_feed_page_#{page}"
      end

      def page_path(page)
        helpers.main_app.all_recording_comments_path(
          recording,
          return_to_options.merge(feed_query_options).merge(page: page)
        )
      end

      def reply_button_resolver
        return if @reply_action.nil?

        @reply_button_resolver ||= lambda do |comment_recording, parent_recording|
          reply_button_options_for(comment_recording, parent_recording)
        end
      end

      attr_reader :recording

      private

      def turbo_frame_request?
        helpers.respond_to?(:turbo_frame_request?) ? helpers.turbo_frame_request? : helpers.request&.headers&.[]("Turbo-Frame").present?
      end

      def top_level_comments_relation
        return @top_level_comments_relation if defined?(@top_level_comments_relation)

        @top_level_comments_relation = if defined?(RecordingStudio::Recording)
                                         RecordingStudio::Recording
                                           .where(parent_recording: recording)
                                           .where(recordable_type: COMMENT_RECORDABLE_TYPE)
                                           .where(trashed_at: nil)
                                           .order(created_at: :asc)
                                           .includes(:recordable)
                                       else
                                         []
                                       end
      end

      def top_level_comments_count
        @top_level_comments_count ||= top_level_comments_relation.size
      end

      def load_replies(top_level_recordings)
        return {} unless defined?(RecordingStudio::Recording)
        return {} if top_level_recordings.empty?

        RecordingStudio::Recording
          .where(parent_recording_id: top_level_recordings.map(&:id))
          .where(recordable_type: COMMENT_RECORDABLE_TYPE)
          .where(trashed_at: nil)
          .order(created_at: :asc)
          .includes(:recordable)
          .group_by(&:parent_recording_id)
      end

      def current_actor
        if helpers.respond_to?(:current_recording_studio_actor)
          helpers.current_recording_studio_actor
        elsif defined?(Current) && Current.respond_to?(:actor)
          Current.actor
        end
      end

      def authorized_to_edit?
        return true unless defined?(RecordingStudioAccessible)

        actor = current_actor
        return false unless actor

        RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :edit)
      end

      def effective_return_to
        @effective_return_to ||= RecordingStudioCommentable::PathSafety.normalize_relative_path(
          @return_to.presence || helpers.params[:return_to].presence
        )
      end

      def return_to_options
        effective_return_to.present? ? { return_to: effective_return_to } : {}
      end

      def feed_query_options
        options = {}
        options[:loading] = loading_mode if paginated?
        options[:page_size] = page_size if paginated?
        options
      end

      def reply_button_options_for(comment_recording, parent_recording = recording)
        default_options = default_reply_button_options_for(comment_recording, parent_recording)
        custom_options = resolve_reply_action(comment_recording, parent_recording, default_options)
        return if custom_options == false

        default_options.merge(custom_options || {})
      end

      def default_reply_button_options_for(comment_recording, _parent_recording)
        DEFAULT_REPLY_BUTTON_OPTIONS.merge(
          url: helpers.recording_studio_commentable.reply_comment_path(
            comment_recording,
            reply_return_to_options
          )
        )
      end

      def resolve_reply_action(comment_recording, parent_recording, default_options)
        case @reply_action
        when nil
          nil
        when false
          false
        when Hash
          @reply_action
        else
          @reply_action.call(
            comment_recording: comment_recording,
            parent_recording: parent_recording,
            component: self,
            default_options: default_options
          )
        end
      end

      def reply_return_to_options
        path = effective_return_to.presence || helpers.request&.fullpath
        path.present? ? { return_to: path } : {}
      end
    end
  end
end
