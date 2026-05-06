# frozen_string_literal: true

require_relative "../../components/component_test_case"

class CommentsButtonComponentTest < ComponentTestCase
  def test_renders_auto_count_and_destination_path_with_current_request_as_return_to
    render_component(
      RecordingStudioCommentable::CommentsButton::Component.new(recording: @public_recording),
      request_url: "/components?tab=button"
    )

    assert_includes rendered_content, "3 Comments"
    assert_includes rendered_content,
                    all_recording_comments_path(@public_recording, return_to: "/components?tab=button")
  end

  def test_uses_explicit_count_for_the_generated_label
    render_component(
      RecordingStudioCommentable::CommentsButton::Component.new(recording: @public_recording, count: 12)
    )

    assert_includes rendered_content, "12 Comments"
  end

  def test_prefers_custom_text_over_generated_label
    render_component(
      RecordingStudioCommentable::CommentsButton::Component.new(
        recording: @public_recording,
        text: "Open discussion"
      )
    )

    assert_includes rendered_content, "Open discussion"
    refute_includes rendered_content, "3 Comments"
  end

  def test_removes_destination_when_current_actor_cannot_view_recording
    Current.actor = @viewer

    render_component(
      RecordingStudioCommentable::CommentsButton::Component.new(recording: @admin_recording),
      request_url: "/components?tab=button"
    )

    refute_includes rendered_content,
                    all_recording_comments_path(@admin_recording, return_to: "/components?tab=button")
    assert_includes rendered_content, "1 Comment"
  end
end