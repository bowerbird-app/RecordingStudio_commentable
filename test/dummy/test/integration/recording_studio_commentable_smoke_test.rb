# frozen_string_literal: true

require_relative "../test_helper"

class RecordingStudioCommentableSmokeTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
  end

  def test_admin_can_view_create_update_and_delete_comments
    created_body = "Smoke test created comment"
    updated_body = "Smoke test updated comment"

    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "Password"
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    get all_recording_comments_path(@public_recording)
    assert_response :success
    assert_includes response.body, "Comments"
    assert_includes response.body, "Post comment"
    assert_includes response.body, "Write your comment..."
    assert_includes response.body, "HOST Reply"
    assert_includes response.body, "Welcome to the shared thread"

    get recording_comments_path(@public_recording, show_comments: true)
    assert_response :success
    assert_includes response.body, "Leave a note, or just read along."
    assert_includes response.body, "Comments"

    get new_recording_comment_path(@public_recording)
    assert_response :success
    assert_includes response.body, "Add comment"
    assert_includes response.body, "Post comment"

    get all_recording_comments_path(@public_recording, loading: "load_more", page_size: 1)
    assert_response :success
    assert_includes response.body, "Load more"

    get all_recording_comments_path(@public_recording, loading: "infinite", page_size: 1)
    assert_response :success
    assert_includes response.body, "Loading more comments..."

    locale_path = RecordingStudioCommentable::Engine.root.join("config/locales/en.yml").to_s
    assert_includes I18n.load_path.map { |path| File.expand_path(path) }, File.expand_path(locale_path)

    post recording_comments_path(@public_recording), params: {
      comment: { body: created_body }
    }
    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")

    created_recording = comment_recording_for_body!(created_body)

    follow_redirect!
    assert_response :success
    assert_includes response.body, created_body

    patch recording_comment_path(@public_recording, created_recording), params: {
      comment: { body: updated_body }
    }
    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")

    follow_redirect!
    assert_response :success
    assert_includes response.body, updated_body
    refute_includes response.body, created_body

    delete recording_comment_path(@public_recording, created_recording)
    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")

    follow_redirect!
    assert_response :success
    refute_includes response.body, updated_body
  end

  def test_denied_view_redirects_with_not_allowed_flash
    quinn = User.find_by!(email: "quinn@admin.com")
    admin_page = Page.find_by!(title: "Admin User owns this document")
    admin_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: admin_page)

    sign_in!(quinn)
    get all_recording_comments_path(admin_recording)

    assert_redirected_to root_path
    assert_equal "You are not allowed to view comments here.", flash[:alert]
  end

  def test_denied_edit_redirects_with_not_allowed_flash
    viewer = User.find_by!(email: "view@admin.com")
    comment_recording = seeded_welcome_comment_recording!

    sign_in!(viewer)
    get edit_recording_comment_path(@public_recording, comment_recording)

    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    assert_equal "You are not allowed to edit this comment.", flash[:alert]
  end

  def test_hidden_comment_partial_omits_author_time_and_avatar
    comment_recording = seeded_welcome_comment_recording!
    comment = comment_recording.recordable
    html = ApplicationController.render(
      partial: "recording_studio_commentable/comments/comment",
      locals: {
        comment_recording: comment_recording,
        parent_recording: @public_recording,
        accessible: false,
        replies: [],
        allow_reply: false
      }
    )

    refute_includes html, comment.author_display_name
    refute_includes html, "Admin User"
    refute_includes html, comment.author_avatar_url.to_s if comment.author_avatar_url.present?
    refute_includes html, comment_recording.created_at.strftime("%b %-d, %Y")
    refute_includes html, comment_recording.created_at.iso8601
    assert_includes html, "Comment hidden"
  end

  def test_home_inbox_omits_unauthorized_comment_author_time_and_avatar
    secret_author = User.create!(
      email: "secret-author@admin.com",
      password: "Password",
      password_confirmation: "Password",
      name: "Secret Author Unique",
      avatar_url: "https://i.pravatar.cc/160?u=secret-author-unique"
    )
    admin_page = Page.find_by!(title: "Admin User owns this document")
    admin_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: admin_page)
    grant = RecordingStudioAccessible.grant_access(
      recording: admin_recording,
      actor: secret_author,
      role: :edit,
      manager_actor: @admin
    )
    assert grant.success?, grant.error.to_s
    result = RecordingStudioCommentable::Services::CreateComment.call(
      parent_recording: admin_recording,
      body: "Secret inbox comment that Quinn must not see",
      author: secret_author
    )
    assert result.success?, result.error.to_s

    quinn = User.find_by!(email: "quinn@admin.com")
    sign_in!(quinn)
    get recording_studio_commentable.root_path

    assert_response :success
    refute_includes response.body, "Secret Author Unique"
    refute_includes response.body, "secret-author-unique"
    refute_includes response.body, "Secret inbox comment that Quinn must not see"
    refute_includes response.body, "Admin-owned page sample comment"
  end

  def test_failed_destroy_flashes_error_not_success
    comment_recording = seeded_welcome_comment_recording!
    failure = RecordingStudioCommentable::Services::BaseService::Result.new(
      success: false,
      error: "boom"
    )

    sign_in!(@admin)
    destroy_class = RecordingStudioCommentable::Services::DestroyComment
    singleton = destroy_class.singleton_class
    original = singleton.instance_method(:call)
    singleton.define_method(:call) { |**| failure }
    begin
      delete recording_comment_path(@public_recording, comment_recording)
    ensure
      singleton.define_method(:call, original)
    end

    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    assert_equal "Couldn't delete that comment.", flash[:alert]
    refute_equal "Comment deleted.", flash[:notice]
    assert RecordingStudio::Recording.unscoped.exists?(comment_recording.id)
  end

  def test_unauthorized_destroy_keeps_comment_and_flashes_not_allowed
    viewer = User.find_by!(email: "view@admin.com")
    comment_recording = seeded_welcome_comment_recording!

    sign_in!(viewer)
    delete recording_comment_path(@public_recording, comment_recording)

    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    assert_equal "You are not allowed to edit this comment.", flash[:alert]
    assert RecordingStudio::Recording.unscoped.exists?(comment_recording.id)
  end

  def test_author_without_admin_cannot_edit_or_delete_own_comment
    quinn = User.find_by!(email: "quinn@admin.com")
    comment_recording = seeded_quinn_top_level_comment_recording!
    original_body = comment_recording.recordable.body

    sign_in!(quinn)
    get edit_recording_comment_path(@public_recording, comment_recording)
    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    assert_equal "You are not allowed to edit this comment.", flash[:alert]

    patch recording_comment_path(@public_recording, comment_recording), params: {
      comment: { body: "Quinn should not be able to rewrite this" }
    }
    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    assert_equal "You are not allowed to edit this comment.", flash[:alert]
    assert_equal original_body, comment_recording.recordable.reload.body

    delete recording_comment_path(@public_recording, comment_recording)
    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    assert_equal "You are not allowed to edit this comment.", flash[:alert]
    assert RecordingStudio::Recording.unscoped.exists?(comment_recording.id)
  end

  def test_direct_update_and_destroy_deny_without_accessible_admin
    quinn = User.find_by!(email: "quinn@admin.com")
    comment_recording = seeded_quinn_top_level_comment_recording!
    original_body = comment_recording.recordable.body

    update_result = RecordingStudioCommentable::Services::UpdateComment.call(
      comment_recording: comment_recording,
      root_recording: @public_recording,
      body: "Quinn must not rewrite this through the service",
      actor: quinn
    )

    assert update_result.failure?
    assert_equal "You are not allowed to edit this comment.", update_result.error
    assert_equal original_body, comment_recording.recordable.reload.body

    destroy_result = RecordingStudioCommentable::Services::DestroyComment.call(
      comment_recording: comment_recording,
      root_recording: @public_recording,
      actor: quinn
    )

    assert destroy_result.failure?
    assert_equal "You are not allowed to edit this comment.", destroy_result.error
    assert RecordingStudio::Recording.unscoped.exists?(comment_recording.id)
  end

  def test_admin_can_edit_someone_elses_comment
    comment_recording = seeded_quinn_top_level_comment_recording!
    updated_body = "Admin rewrote Quinn's note"

    sign_in!(@admin)
    patch recording_comment_path(@public_recording, comment_recording), params: {
      comment: { body: updated_body }
    }

    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    assert_equal updated_body, comment_recording.reload.recordable.body
  end

  def test_nil_layout_follows_recording_studio_configuration
    sign_in!(@admin)
    with_commentable_layout(nil) do
      RecordingStudio.configuration.layout = "flat_pack_pseudo_top_nav"

      get all_recording_comments_path(@public_recording)

      assert_response :success
      assert_includes response.body, "Pseudo layout preview"
      refute_includes response.body, 'data-recording-studio-default-layout="true"'
    end
  end

  def test_false_layout_renders_without_a_host_shell
    sign_in!(@admin)
    with_commentable_layout(false) do
      RecordingStudio.configuration.layout = "flat_pack_pseudo_top_nav"

      get all_recording_comments_path(@public_recording)

      assert_response :success
      assert_includes response.body, "Comments"
      refute_includes response.body, "Pseudo layout preview"
      refute_includes response.body, 'data-recording-studio-default-layout="true"'
      refute_includes response.body, "<html"
    end
  end

  def test_named_layout_uses_that_shell
    sign_in!(@admin)
    with_commentable_layout("flat_pack_pseudo_top_nav") do
      RecordingStudio.configuration.layout = "application"

      get all_recording_comments_path(@public_recording)

      assert_response :success
      assert_includes response.body, "Pseudo layout preview"
      refute_includes response.body, "container mx-auto mt-28"
    end
  end

  def test_callable_layout_receives_the_controller_and_picks_the_shell
    sign_in!(@admin)
    seen = nil
    with_commentable_layout(->(controller:) {
      seen = controller
      "flat_pack_pseudo_top_nav"
    }) do
      RecordingStudio.configuration.layout = "application"

      get all_recording_comments_path(@public_recording)

      assert_response :success
      assert_includes response.body, "Pseudo layout preview"
      assert_kind_of RecordingStudioCommentable::ApplicationController, seen
    end
  end

  def test_comment_recordable_is_registered_as_a_capability_owned_child_type
    assert_includes RecordingStudio.configuration.recordable_types, "RecordingStudioCommentable::Comment"
    assert RecordingStudio.configuration.capability_enabled?(:commentable, for_type: "Page")
    assert_includes RecordingStudio.child_recordable_types_for("Page"), "RecordingStudioCommentable::Comment"
    assert_includes RecordingStudio.allowed_parent_types_for("RecordingStudioCommentable::Comment"), "Page"
    assert_includes RecordingStudio.allowed_parent_types_for("RecordingStudioCommentable::Comment"),
                    "RecordingStudioCommentable::Comment"
  end

  private

  def comment_recording_for_body!(body)
    comment = RecordingStudioCommentable::Comment.find_by!(body: body)
    RecordingStudio::Recording.unscoped.find_by!(recordable: comment)
  end

  def seeded_welcome_comment_recording!
    comment_recording_for_body!(
      "Welcome to the shared thread. Use this page to verify the default comments feed with seeded content."
    )
  end

  def seeded_quinn_top_level_comment_recording!
    comment_recording_for_body!(
      "A second top-level comment gives the paginated feed examples enough items to demonstrate the different loading modes."
    )
  end

  def sign_in!(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "Password"
      }
    }
    assert_response :redirect
  end

  def with_commentable_layout(layout)
    previous_commentable = RecordingStudioCommentable.configuration.layout
    previous_core = RecordingStudio.configuration.layout
    RecordingStudioCommentable.configuration.layout = layout
    yield
  ensure
    RecordingStudioCommentable.configuration.layout = previous_commentable
    RecordingStudio.configuration.layout = previous_core
  end
end

class CommentsApiTest < ActionDispatch::IntegrationTest
  setup do
    skip "recording_studio_api is not available" unless defined?(RecordingStudioApi)

    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
    @admin_page = Page.find_by!(title: "Admin User owns this document")
    @admin_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @admin_page)
    @folder = Folder.find_by!(name: "Reference Folder")
    @folder_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @folder)
    @admin_token = issue_token(access_point: @public_recording, manager: @admin, role: :admin, name: "Admin comments")
    @edit_token = issue_token(access_point: @public_recording, manager: @admin, role: :edit, name: "Edit comments")
    @view_token = issue_token(access_point: @public_recording, manager: @admin, role: :view, name: "View comments")
  end

  def test_registers_comment_recordable_type_and_write_handlers
    registration = RecordingStudioApi.recordable_registration_for(
      RecordingStudioCommentable::Api::RECORDABLE_TYPE
    )

    refute_nil registration
    assert_equal %i[create destroy index show update], registration.operations.sort
    assert_equal %w[body], registration.writable_attributes
    assert_equal false, registration.auto_capability_actions
    assert registration.fields.key?("comment_count")
    assert registration.relationships.key?("replies")
    assert_equal RecordingStudioCommentable::Api::Create,
                 RecordingStudioApi.resource_handler(RecordingStudioCommentable::Api::RECORDABLE_TYPE, :create)
    assert_equal RecordingStudioCommentable::Api::Update,
                 RecordingStudioApi.resource_handler(RecordingStudioCommentable::Api::RECORDABLE_TYPE, :update)
    assert_equal RecordingStudioCommentable::Api::Destroy,
                 RecordingStudioApi.resource_handler(RecordingStudioCommentable::Api::RECORDABLE_TYPE, :destroy)
  end

  def test_eager_loaded_api_admin_api_stays_on_the_host_recordable_type_list
    require "recording_studio_api/admin_api" unless defined?(RecordingStudioApi::AdminApi)

    assert_includes RecordingStudio.configuration.recordable_types, "RecordingStudioApi::AdminApi"
    assert_empty RecordingStudioApi.configuration.admin_root_recordable_type_names
    assert RecordingStudio.validate_recordable_declarations!
  end

  def test_index_show_create_reply_update_and_destroy
    get "/recording_studio_api/api/v1/comments",
        params: { parent_id: @public_recording.id, include: "replies" },
        headers: bearer(@view_token)
    assert_response :success
    body = json_body
    assert_equal "comments", body.fetch("resource")
    records = body.fetch("records")
    refute_empty records
    sample = records.first
    assert sample.key?("comment_count")
    assert sample.key?("body")

    show_id = sample.fetch("id")
    get "/recording_studio_api/api/v1/comments/#{show_id}", headers: bearer(@view_token)
    assert_response :success
    assert_equal show_id, json_body.fetch("id")

    post "/recording_studio_api/api/v1/comments",
         params: { parent_id: @public_recording.id, body: "API created comment" },
         headers: bearer(@edit_token),
         as: :json
    assert_response :created
    created_id = json_body.fetch("id")
    assert_equal "API created comment", json_body.fetch("body")

    post "/recording_studio_api/api/v1/comments",
         params: { parent_id: created_id, body: "API reply" },
         headers: bearer(@edit_token),
         as: :json
    assert_response :created
    assert_equal created_id, json_body.fetch("parent_id")
    assert_equal "API reply", json_body.fetch("body")

    patch "/recording_studio_api/api/v1/comments/#{created_id}",
          params: { body: "API updated comment" },
          headers: bearer(@admin_token),
          as: :json
    assert_response :success
    assert_equal "API updated comment", json_body.fetch("body")

    delete "/recording_studio_api/api/v1/comments/#{created_id}", headers: bearer(@admin_token)
    assert_response :success
    assert_equal true, json_body.fetch("deleted")
    assert_equal "trashed", json_body.fetch("deleted_via")
  end

  def test_unauthenticated_requests_are_unauthorized
    get "/recording_studio_api/api/v1/comments", params: { parent_id: @public_recording.id }
    assert_response :unauthorized
  end

  def test_view_role_cannot_create_update_or_destroy
    post "/recording_studio_api/api/v1/comments",
         params: { parent_id: @public_recording.id, body: "View should not post" },
         headers: bearer(@view_token),
         as: :json
    assert_response :forbidden

    comment_id = seeded_welcome_comment_id

    patch "/recording_studio_api/api/v1/comments/#{comment_id}",
          params: { body: "View should not edit" },
          headers: bearer(@view_token),
          as: :json
    assert_response :forbidden

    delete "/recording_studio_api/api/v1/comments/#{comment_id}", headers: bearer(@view_token)
    assert_response :forbidden
  end

  def test_edit_role_cannot_update_or_destroy
    comment_id = seeded_welcome_comment_id

    patch "/recording_studio_api/api/v1/comments/#{comment_id}",
          params: { body: "Edit should not rewrite" },
          headers: bearer(@edit_token),
          as: :json
    assert_response :forbidden

    delete "/recording_studio_api/api/v1/comments/#{comment_id}", headers: bearer(@edit_token)
    assert_response :forbidden
  end

  def test_foreign_workspace_returns_not_found
    other_token = issue_token(access_point: @admin_recording, manager: @admin, role: :admin, name: "Other page")
    comment_id = seeded_welcome_comment_id

    get "/recording_studio_api/api/v1/comments/#{comment_id}", headers: bearer(other_token)
    assert_response :not_found

    patch "/recording_studio_api/api/v1/comments/#{comment_id}",
          params: { body: "Cross workspace rewrite" },
          headers: bearer(other_token),
          as: :json
    assert_response :not_found

    delete "/recording_studio_api/api/v1/comments/#{comment_id}", headers: bearer(other_token)
    assert_response :not_found

    post "/recording_studio_api/api/v1/comments",
         params: { parent_id: @public_recording.id, body: "Cross workspace create" },
         headers: bearer(other_token),
         as: :json
    assert_response :not_found
  end

  def test_create_refuses_when_commentable_is_off
    folder_token = issue_token(access_point: @folder_recording, manager: @admin, role: :admin, name: "Folder comments")

    post "/recording_studio_api/api/v1/comments",
         params: { parent_id: @folder_recording.id, body: "Folder should not take comments" },
         headers: bearer(folder_token),
         as: :json
    assert_response :forbidden
  end

  def test_blank_body_is_unprocessable
    post "/recording_studio_api/api/v1/comments",
         params: { parent_id: @public_recording.id, body: "" },
         headers: bearer(@edit_token),
         as: :json
    assert_response :unprocessable_entity
  end

  private

  def json_body
    JSON.parse(response.body)
  end

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end

  def seeded_welcome_comment_id
    comment = RecordingStudioCommentable::Comment.find_by!(
      body: "Welcome to the shared thread. Use this page to verify the default comments feed with seeded content."
    )
    RecordingStudio::Recording.unscoped.find_by!(recordable: comment).id
  end

  def issue_token(access_point:, manager:, role:, name:)
    RecordingStudioAccessible::AccessCreationContext.allow do
      provision = RecordingStudioApi::Services::ProvisionApiClient.call(
        access_point_recording: access_point,
        manager_actor: manager,
        role: role,
        name: "#{name}-#{SecureRandom.hex(4)}"
      )
      raise provision.error unless provision.success?

      payload = provision.value
      token_result = RecordingStudioApi::Services::IssueOauthAccessToken.call(
        grant_type: "client_credentials",
        client_id: payload.fetch(:credential).oauth_client_id,
        client_secret: payload.fetch(:token)
      )
      raise token_result.error unless token_result.success?

      token_result.value.fetch(:access_token)
    end
  end
end