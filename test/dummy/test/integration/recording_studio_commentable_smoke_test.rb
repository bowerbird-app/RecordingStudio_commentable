# frozen_string_literal: true

require_relative "../test_helper"

class RecordingStudioCommentableSmokeTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed

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
    assert_includes response.body, "Welcome to the shared thread"

    post recording_comments_path(@public_recording), params: {
      comment: { body: created_body }
    }
    assert_redirected_to all_recording_comments_path(@public_recording)

    created_recording = comment_recording_for_body!(created_body)

    follow_redirect!
    assert_response :success
    assert_includes response.body, created_body

    patch recording_comment_path(@public_recording, created_recording), params: {
      comment: { body: updated_body }
    }
    assert_redirected_to all_recording_comments_path(@public_recording)

    follow_redirect!
    assert_response :success
    assert_includes response.body, updated_body
    refute_includes response.body, created_body

    delete recording_comment_path(@public_recording, created_recording)
    assert_redirected_to all_recording_comments_path(@public_recording)

    follow_redirect!
    assert_response :success
    refute_includes response.body, updated_body
  end

  private

  def comment_recording_for_body!(body)
    comment = RecordingStudioCommentable::Comment.find_by!(body: body)
    RecordingStudio::Recording.unscoped.find_by!(recordable: comment)
  end
end