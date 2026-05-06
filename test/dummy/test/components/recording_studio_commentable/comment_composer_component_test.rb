# frozen_string_literal: true

require_relative "../../components/component_test_case"

class CommentComposerComponentTest < ComponentTestCase
  def test_renders_new_comment_composer_with_rich_text_input
    render_component(
      RecordingStudioCommentable::CommentComposer::Component.new(
        comment: RecordingStudioCommentable::Comment.new,
        url: recording_comments_path(@public_recording)
      )
    )

    assert_includes rendered_content, "Write your comment..."
    assert_includes rendered_content, 'name="comment[body]"'
    assert_includes rendered_content, "Post comment"
  end

  def test_renders_parent_comment_id_hidden_field_when_replying
    render_component(
      RecordingStudioCommentable::CommentComposer::Component.new(
        comment: RecordingStudioCommentable::Comment.new,
        url: recording_comments_path(@public_recording),
        parent_comment_id: "reply-123"
      )
    )

    assert_includes rendered_content, 'name="parent_comment_id"'
    assert_includes rendered_content, 'value="reply-123"'
  end

  def test_renders_cancel_and_save_actions_for_editing
    comment = RecordingStudioCommentable::Comment.new(body: "Updated body")
    comment.save!(validate: false)

    render_component(
      RecordingStudioCommentable::CommentComposer::Component.new(
        comment: comment,
        url: recording_comments_path(@public_recording),
        cancel_path: all_recording_comments_path(@public_recording)
      )
    )

    assert_includes rendered_content, "Cancel"
    assert_includes rendered_content, "Save changes"
    assert_includes rendered_content, all_recording_comments_path(@public_recording)
  end
end