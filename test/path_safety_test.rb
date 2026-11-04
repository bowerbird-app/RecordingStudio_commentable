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

  def test_normalize_relative_path_rejects_backslash
    assert_nil RecordingStudioCommentable::PathSafety.normalize_relative_path("/comments\\evil")
  end

  def test_normalize_relative_path_rejects_control_characters
    assert_nil RecordingStudioCommentable::PathSafety.normalize_relative_path("/comments\u0000")
    assert_nil RecordingStudioCommentable::PathSafety.normalize_relative_path("/comments\n")
  end

  def test_normalize_relative_path_rejects_encoded_crlf
    assert_nil RecordingStudioCommentable::PathSafety.normalize_relative_path("/comments?next=%0d%0aSet-Cookie:x")
    assert_nil RecordingStudioCommentable::PathSafety.normalize_relative_path("/comments/%0a")
  end

  def test_safe_avatar_url_allows_https
    assert_equal "https://cdn.example/a.png",
                 RecordingStudioCommentable::PathSafety.safe_avatar_url("https://cdn.example/a.png")
  end

  def test_safe_avatar_url_allows_http
    assert_equal "http://cdn.example/a.png",
                 RecordingStudioCommentable::PathSafety.safe_avatar_url("http://cdn.example/a.png")
  end

  def test_safe_avatar_url_allows_relative_image_paths
    assert_equal "/avatars/me.png",
                 RecordingStudioCommentable::PathSafety.safe_avatar_url("/avatars/me.png")
    assert_equal "avatars/me.webp",
                 RecordingStudioCommentable::PathSafety.safe_avatar_url("avatars/me.webp")
  end

  def test_safe_avatar_url_rejects_javascript_and_data
    assert_nil RecordingStudioCommentable::PathSafety.safe_avatar_url("javascript:alert(1)")
    assert_nil RecordingStudioCommentable::PathSafety.safe_avatar_url("data:image/png;base64,aaaa")
  end

  def test_safe_avatar_url_rejects_protocol_relative_and_userinfo
    assert_nil RecordingStudioCommentable::PathSafety.safe_avatar_url("//evil.example/a.png")
    assert_nil RecordingStudioCommentable::PathSafety.safe_avatar_url("https://user:pass@cdn.example/a.png")
  end
end
