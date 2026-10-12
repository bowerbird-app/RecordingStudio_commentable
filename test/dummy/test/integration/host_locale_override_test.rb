# frozen_string_literal: true

require_relative "../test_helper"

class HostLocaleOverrideTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
  end

  def test_host_locale_file_overrides_gem_reply_label_on_comments_page
    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "Password"
      }
    }
    assert_response :redirect

    get all_recording_comments_path(@public_recording)
    assert_response :success
    assert_includes response.body, "HOST Reply"

    fragment = Nokogiri::HTML.fragment(response.body)
    reply_labels = fragment.css("a, button").map { |node| node.text.strip }
    assert_includes reply_labels, "HOST Reply"
    refute_includes reply_labels, "Reply"
  end
end
