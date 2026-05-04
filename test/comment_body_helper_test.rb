# frozen_string_literal: true

require "test_helper"

class CommentBodyHelperTest < Minitest::Test
  def setup
    @helper = Class.new do
      include RecordingStudioCommentable::CommentBodyHelper
    end.new
  end

  def test_returns_plain_text_for_short_body
    assert_equal "Short comment", @helper.truncate_comment_body("Short comment")
  end

  def test_strips_html_and_truncates_on_word_boundary
    body = "<p>This is a <strong>long</strong> comment with extra details for preview text.</p>"

    assert_equal "This is a long comment...", @helper.truncate_comment_body(body, length: 27)
  end

  def test_accepts_comment_like_objects
    comment = Struct.new(:body).new("<p>Comment body from model</p>")

    assert_equal "Comment body from model", @helper.truncate_comment_body(comment)
  end

  def test_returns_empty_string_for_blank_body
    assert_equal "", @helper.truncate_comment_body("   ")
  end
end