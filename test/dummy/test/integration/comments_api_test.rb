# frozen_string_literal: true

require_relative "../test_helper"

class CommentsApiTest < ActionDispatch::IntegrationTest
  setup do
    skip "recording_studio_api is not available" unless defined?(RecordingStudioApi)

    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @viewer = User.find_by!(email: "view@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
    @admin_page = Page.find_by!(title: "Admin User owns this document")
    @admin_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @admin_page)
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

  def test_does_not_read_another_workspace
    other_token = issue_token(access_point: @admin_recording, manager: @admin, role: :admin, name: "Other page")

    get "/recording_studio_api/api/v1/comments",
        params: { parent_id: @public_recording.id },
        headers: bearer(other_token)
    assert_response :success
    ids = json_body.fetch("records").map { |record| record.fetch("id") }
    refute_includes ids, seeded_welcome_comment_id
  end

  def test_create_comment_service_denies_view_only_actor
    result = RecordingStudioCommentable::Services::CreateComment.call(
      parent_recording: @public_recording,
      body: "Viewer must not post through the service",
      author: @viewer
    )

    assert result.failure?
    assert_equal "You are not allowed to post comments here.", result.error
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
