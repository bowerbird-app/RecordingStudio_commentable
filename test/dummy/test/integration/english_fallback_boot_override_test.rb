# frozen_string_literal: true

require_relative "../test_helper"

# Boot-loaded host English override for common.reply wins on a real comments
# page. Fixture (already on main — keep it):
# test/dummy/config/locales/recording_studio_commentable.host.en.yml
#
# No runtime I18n.load_path <<. Preconditions: file exists, I18n.t returns HOST,
# load_path untouched, main English "Reply" absent from that key.
class EnglishFallbackBootOverrideTest < ActionDispatch::IntegrationTest
  HOST_OVERRIDE_LOCALE =
    Rails.root.join("config/locales/recording_studio_commentable.host.en.yml").to_s.freeze
  KEY = "recording_studio.commentable.common.reply"
  HOST = "HOST Reply"
  GEM_ENGLISH = "Reply"

  setup do
    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)

    # Force I18n to initialize before store_translations / assertions.
    I18n.t("recording_studio.commentable.common.comments")
  end

  test "boot-loaded host english override wins on comments page reply label" do
    assert_boot_loaded_override_preconditions!

    sign_in_admin!
    get all_recording_comments_path(@public_recording)

    assert_response :success
    assert_includes @response.body, HOST

    fragment = Nokogiri::HTML.fragment(@response.body)
    reply_labels = fragment.css("a, button").map { |node| node.text.strip }
    assert_includes reply_labels, HOST
    refute_includes reply_labels, GEM_ENGLISH

    assert_equal HOST, I18n.t(KEY)
    assert_equal HOST, RecordingStudio.t(KEY)
    assert_equal HOST, RecordingStudio::Translation.t(KEY)
  end

  private

  def sign_in_admin!
    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "Password"
      }
    }
    assert_response :redirect
  end

  def assert_boot_loaded_override_preconditions!
    assert File.exist?(HOST_OVERRIDE_LOCALE), "expected boot-loaded host override at #{HOST_OVERRIDE_LOCALE}"
    assert_includes File.expand_path(HOST_OVERRIDE_LOCALE), "/config/locales/"

    load_path = I18n.load_path.map { |path| File.expand_path(path) }
    gem_en = File.expand_path(RecordingStudioCommentable::Engine.root.join("config/locales/en.yml"))
    host_en = File.expand_path(HOST_OVERRIDE_LOCALE)

    assert_includes load_path, gem_en
    assert_includes load_path, host_en
    assert_operator load_path.index(gem_en), :<, load_path.index(host_en),
                    "gem en.yml must load before host boot override"

    original_load_path = I18n.load_path.dup
    assert_equal HOST, I18n.t(KEY), "I18n.t must return HOST before the page render"
    assert_equal original_load_path, I18n.load_path, "load_path must stay untouched"
    refute_equal GEM_ENGLISH, I18n.t(KEY)
    assert_equal HOST, RecordingStudio.t(KEY)
  end
end
