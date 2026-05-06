# frozen_string_literal: true

require_relative "../../components/component_test_case"
require "cgi"

class CommentsFeedComponentTest < ComponentTestCase
  def test_renders_full_thread_with_composer_and_nested_reply_content
    fragment = render_component(
      RecordingStudioCommentable::CommentsFeed::Component.new(
        recording: @public_recording,
        include_composer: true,
        can_create_comment: true
      ),
      request_url: "/components?tab=feed"
    )

    assert_includes rendered_content, "Write your comment..."
    assert_includes fragment.text, "Welcome to the shared thread"
    assert_includes fragment.text, "Reply sample: Quinn can respond here"
    assert_equal 2, fragment.css("a").count { |link| link.text.strip == "Reply" }
  end

  def test_hides_composer_when_creation_is_not_allowed
    fragment = render_component(
      RecordingStudioCommentable::CommentsFeed::Component.new(
        recording: @public_recording,
        include_composer: true,
        can_create_comment: false
      )
    )

    refute_includes rendered_content, "Write your comment..."
    assert_includes fragment.text, "Comments"
  end

  def test_renders_load_more_pagination_without_second_page_comments
    render_component(
      RecordingStudioCommentable::CommentsFeed::Component.new(
        recording: @public_recording,
        mode: :load_more,
        page_size: 1,
        include_composer: true,
        can_create_comment: true,
        return_to: "/components"
      ),
      request_url: "/components?tab=feed"
    )

    top_level_comment_bodies = [
      "Welcome to the shared thread. Use this page to verify the default comments feed with seeded content.",
      "A second top-level comment gives the paginated feed examples enough items to demonstrate the different loading modes."
    ]

    rendered_top_level_bodies = top_level_comment_bodies.select { |body| rendered_content.include?(body) }

    assert_equal 1, rendered_top_level_bodies.size
    assert_equal 1, Nokogiri::HTML.fragment(rendered_content).css("a").count { |link| link.text.strip == "Reply" }
    expected_path = all_recording_comments_path(@public_recording,
                                                return_to: "/components",
                                                loading: :load_more,
                                                page_size: 1,
                                                page: 2)

    assert_includes rendered_content, CGI.escapeHTML(expected_path)
    assert_includes rendered_content, "Load more"
  end

  def test_renders_infinite_scroll_placeholder_for_paginated_mode
    expected_path = all_recording_comments_path(@public_recording, loading: :infinite, page_size: 1, page: 2)

    render_component(
      RecordingStudioCommentable::CommentsFeed::Component.new(
        recording: @public_recording,
        mode: :infinite,
        page_size: 1
      )
    )

    assert_includes rendered_content, 'data-controller="infinite-scroll"'
    assert_includes rendered_content, "Loading more comments..."
  assert_includes rendered_content, CGI.escapeHTML(expected_path)
  end

  def test_renders_page_only_markup_for_turbo_frame_requests
    render_component_in_turbo_frame(
      RecordingStudioCommentable::CommentsFeed::Component.new(
        recording: @public_recording,
        mode: :load_more,
        page_size: 1
      ),
      request_url: "/recordings/#{@public_recording.id}/comments/all?loading=load_more&page_size=1&page=2",
      turbo_frame: "comments_feed_page_2"
    )

    assert_includes rendered_content, 'id="comments_feed_page_2"'
    refute_includes rendered_content, "Write your comment..."
    refute_includes rendered_content, ">Comments <"
  end

  def test_uses_custom_reply_action_over_default_reply_route
    custom_url = recording_comments_path(@public_recording, show_comments: true)

    render_component(
      RecordingStudioCommentable::CommentsFeed::Component.new(
        recording: @public_recording,
        reply_action: lambda do |default_options:, **|
          default_options.merge(url: custom_url, text: "Reply inline")
        end
      )
    )

    assert_includes rendered_content, "Reply inline"
    assert_includes rendered_content, custom_url
    refute_includes rendered_content, reply_comment_path_fragment
  end

  def test_drops_external_return_to_values_from_composer_url
    render_component(
      RecordingStudioCommentable::CommentsFeed::Component.new(
        recording: @public_recording,
        include_composer: true,
        can_create_comment: true,
        return_to: "https://example.com/escape"
      ),
      request_url: "/components?tab=feed"
    )

    assert_includes rendered_content, recording_comments_path(@public_recording, inline_composer: true)
    refute_includes rendered_content, "example.com/escape"
  end

  private

  def reply_comment_path_fragment
    "/commentable/comments/"
  end
end