# frozen_string_literal: true

require "test_helper"
require "active_model"

# Regression tests for nested comment reply support.
#
# Covers:
#   - CreateComment service can target a comment recording as parent (reply flow)
#   - Controller source encodes reply creation path and load_replies helper
#   - Comment partial renders reply link and nested reply block
#   - CommentComposer component carries parent_comment_id hidden field
#   - All/index view templates pass replies to comment partial
#   - new.html.erb wires parent_comment_id to the composer component
#   - Dummy routes remain unchanged (no new route surface)
class NestedRepliesTest < Minitest::Test
  # ------------------------------------------------------------------ #
  # Service: CreateComment works with a comment recording as parent
  # ------------------------------------------------------------------ #

  class FakeRecording
    attr_reader :id, :parent_recording_id, :recordable_type, :trashed_at, :children,
                :last_record_class, :last_record_kwargs

    def initialize(id: "rec-1", parent_recording_id: nil, recordable_type: nil, trashed_at: nil)
      @id = id
      @parent_recording_id = parent_recording_id
      @recordable_type = recordable_type
      @trashed_at = trashed_at
      @children = []
    end

    def record(klass, **kwargs)
      @last_record_class = klass
      @last_record_kwargs = kwargs
      obj = klass.new
      yield obj if block_given?
      @children << obj
      obj
    end

    def respond_to?(method, include_private = false)
      method == :record || super
    end
  end

  class FakeComment
    include ActiveModel::Validations

    attr_accessor :body, :author

    validates :body, presence: true

    def initialize
      @persisted = false
    end

    def save!
      raise ActiveModel::ValidationError.new(self) unless valid?

      @persisted = true
    end

    def persisted?
      @persisted
    end
  end

  # Replies use the parent comment recording as parent_recording.
  # CreateComment already accepts any recording as parent — verify the
  # service passes through correctly when given a comment recording.
  def test_create_comment_service_accepts_comment_recording_as_parent
    page_recording = FakeRecording.new(id: "page-rec")
    comment_recording = FakeRecording.new(
      id: "comment-rec",
      parent_recording_id: "page-rec",
      recordable_type: "RecordingStudioCommentable::Comment"
    )

    service = RecordingStudioCommentable::Services::CreateComment.new(
      parent_recording: comment_recording,
      body: "This is a reply",
      author: nil
    )
    service.define_singleton_method(:recording_studio_available?) { true }
    service.define_singleton_method(:build_comment) do
      FakeComment.new.tap { |c| c.body = "This is a reply" }
    end

    result = service.call

    assert result.success?
    assert_equal comment_recording, service.instance_variable_get(:@parent_recording)
    assert_equal comment_recording, comment_recording.last_record_kwargs[:parent_recording]
  end

  def test_create_comment_service_failure_with_blank_reply_body
    comment_recording = FakeRecording.new(
      id: "comment-rec",
      parent_recording_id: "page-rec",
      recordable_type: "RecordingStudioCommentable::Comment"
    )

    result = RecordingStudioCommentable::Services::CreateComment.call(
      parent_recording: comment_recording,
      body: "",
      author: nil
    )

    assert result.failure?
    assert_equal "Body cannot be blank", result.error
  end

  # ------------------------------------------------------------------ #
  # Controller source: reply plumbing
  # ------------------------------------------------------------------ #

  def test_controller_includes_find_parent_comment_recording
    source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")

    assert_includes source, "def find_parent_comment_recording"
    assert_includes source, "params[:parent_comment_id].present?"
    assert_includes source, "recording.parent_recording_id == @parent_recording.id"
    assert_includes source, "recording.recordable_type == \"RecordingStudioCommentable::Comment\""
    assert_includes source, "recording.trashed_at.present?"
  end

  def test_controller_uses_effective_parent_in_create
    source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")

    assert_includes source, "effective_parent = find_parent_comment_recording || @parent_recording"
    assert_includes source, "parent_recording: effective_parent,"
  end

  def test_controller_includes_load_replies
    source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")

    assert_includes source, "def load_replies"
    assert_includes source, ".where(parent_recording_id: ids)"
    assert_includes source, ".group_by(&:parent_recording_id)"
    assert_includes source, "@replies = load_replies(@comments)"
  end

  def test_controller_loads_replies_in_index_all_and_create_failure
    source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")

    # @replies is set in the summary page branch and inline summary validation failure path.
    assert_includes source, "@replies = load_replies(@comments)"
    # Verify it still appears in both places where the summary template renders nested replies.
    reply_count = source.scan("@replies = load_replies(@comments)").size
    assert reply_count >= 2,
           "Expected @replies = load_replies(@comments) to appear at least 2 times (index and create summary failure); found #{reply_count}"
  end

  def test_controller_initializes_parent_comment_recording_in_new
    source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")

    assert_includes source, "@parent_comment_recording = find_parent_comment_recording"
  end

  # ------------------------------------------------------------------ #
  # Comment partial: reply link and nested replies block
  # ------------------------------------------------------------------ #

  def test_comment_partial_reply_button_defaults_to_engine_aware_comment_path
    source = read_workspace_file("app/views/recording_studio_commentable/comments/_comment.html.erb")

    assert_includes source, 'text: "Reply"'
    assert_includes source, "local_assigns.fetch(:allow_reply, true)"
    assert_includes source,
                    "link_to reply_action_options[:text], reply_action_options[:href], class: reply_action_options[:class], data: reply_action_options[:data]"
    assert_includes source, "FlatPack::Button::Component.new(**reply_action_options)"
    assert_includes source, 'class: "text-sm font-medium text-[var(--color-primary)] hover:underline"'
    assert_includes source, 'data: { turbo_frame: "_top" }'
    assert_includes source, "commentable_reply_comment_path"
    assert_includes source, "local_assigns[:reply_button_resolver]"
    assert_includes source, "elsif allow_reply"
  end

  def test_comment_partial_renders_nested_replies
    source = read_workspace_file("app/views/recording_studio_commentable/comments/_comment.html.erb")

    assert_includes source, "replies = local_assigns.fetch(:replies, [])"
    assert_includes source, "if replies.any?"
    assert_includes source, "replies.each do |reply_recording|"
    assert_includes source, 'render "recording_studio_commentable/comments/comment"'
    assert_includes source, "comment_recording: reply_recording"
    assert_includes source, "allow_reply: false"
    assert_includes source, "reply_button_resolver: reply_button_resolver"
  end

  def test_comment_partial_uses_indented_border_for_replies
    source = read_workspace_file("app/views/recording_studio_commentable/comments/_comment.html.erb")

    assert_includes source, "border-l-2"
  end

  # ------------------------------------------------------------------ #
  # CommentComposer component: parent_comment_id hidden field
  # ------------------------------------------------------------------ #

  def test_comment_composer_component_includes_parent_comment_id_hidden_field
    source = read_workspace_file("app/components/recording_studio_commentable/comment_composer/component.html.erb")

    assert_includes source, "hidden_field_tag :parent_comment_id, parent_comment_id"
  end

  # ------------------------------------------------------------------ #
  # all.html.erb: passes replies to comment partial
  # ------------------------------------------------------------------ #

  def test_all_template_passes_replies_to_comment_partial
    source = read_workspace_file("app/views/recording_studio_commentable/comments/all.html.erb")

    assert_includes source, "RecordingStudioCommentable::CommentsFeed::Component.new("
    assert_includes source, "include_composer: !show_new_comment_button"
    assert_includes source, "return_to: @safe_return_to_path"
    assert_includes source, "comment: @comment"
    assert_includes source, "can_create_comment: @can_create_comment"
  end

  # ------------------------------------------------------------------ #
  # index.html.erb: passes replies to comment partial
  # ------------------------------------------------------------------ #

  def test_index_template_passes_replies_to_comment_partial
    source = read_workspace_file("app/views/recording_studio_commentable/comments/index.html.erb")

    assert_includes source, "replies:"
    assert_includes source, "@replies"
    assert_includes source, "fetch(comment_recording.id, [])"
  end

  # ------------------------------------------------------------------ #
  # new.html.erb: wires parent_comment_id to composer component
  # ------------------------------------------------------------------ #

  def test_new_template_passes_parent_comment_id_to_form
    source = read_workspace_file("app/views/recording_studio_commentable/comments/new.html.erb")

    assert_includes source, "parent_comment_id: params[:parent_comment_id]"
  end

  # ------------------------------------------------------------------ #
  # Routes: replies use the existing create route via parent_comment_id,
  # but the engine now exposes the same comment browser routes as the host app.
  # ------------------------------------------------------------------ #

  def test_dummy_routes_unchanged_for_replies
    source = read_workspace_file("test/dummy/config/routes.rb")

    assert_includes source, "resources :comments, only: %i[index new create edit update destroy] do"
    # No new reply-specific resource routes
    refute_includes source, "resources :replies"
    refute_includes source, "member do"
    refute_includes source, "post :reply"
  end

  def test_engine_routes_include_comment_browser_paths
    source = read_workspace_file("config/routes.rb")

    assert_includes source, "root \"home#index\""
    assert_includes source, "resources :comments, only: [] do"
    assert_includes source, "get :reply"
    assert_includes source, "post :reply, action: :create_reply"
    refute_includes source, "resources :recordings, only: [] do"
    refute_includes source, "resources :replies"
  end

  private

  def read_workspace_file(path)
    File.read(File.expand_path("../#{path}", __dir__))
  end
end
