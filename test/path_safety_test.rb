# frozen_string_literal: true

require "test_helper"

class PathSafetyTest < Minitest::Test
  def test_normalize_relative_path_preserves_internal_paths_and_queries
    assert_equal "/recordings/1/comments?show_comments=true",
                 RecordingStudioCommentable::PathSafety.normalize_relative_path(
                   "/recordings/1/comments?show_comments=true"
                 )
  end

  def test_normalize_relative_path_rejects_external_urls
    assert_nil RecordingStudioCommentable::PathSafety.normalize_relative_path("https://evil.example/steal")
  end

  def test_normalize_relative_path_rejects_script_schemes
    assert_nil RecordingStudioCommentable::PathSafety.normalize_relative_path("javascript:alert(1)")
  end
end