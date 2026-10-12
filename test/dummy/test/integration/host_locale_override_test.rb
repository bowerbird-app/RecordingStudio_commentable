# frozen_string_literal: true

require_relative "../test_helper"

class HostLocaleOverrideTest < ActionDispatch::IntegrationTest
  HOST_OVERRIDE_LOCALE = File.expand_path("../locales/commentable_host_override.en.yml", __dir__).freeze

  setup do
    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
  end

  # Always-loaded boot-order guard (test/dummy/config/locales/...host.en.yml)
  # overrides a rarely shown key. Do not delete this assertion.
  def test_always_loaded_host_locale_overrides_rarely_shown_comment_hidden_key
    assert_equal "HOST Comment hidden",
                 I18n.t("recording_studio.commentable.comment.hidden")
    assert_equal "Reply", I18n.t("recording_studio.commentable.common.reply")
  end

  def test_test_only_host_locale_fixture_overrides_reply_on_comments_page
    with_restored_i18n_backend do
      I18n.load_path << HOST_OVERRIDE_LOCALE
      I18n.backend.load_translations(HOST_OVERRIDE_LOCALE)

      post user_session_path, params: {
        user: {
          email: @admin.email,
          password: "Password"
        }
      }
      assert_response :redirect

      get all_recording_comments_path(@public_recording)
      assert_response :success
      assert_includes response.body, "HOST Reply wins"

      fragment = Nokogiri::HTML.fragment(response.body)
      reply_labels = fragment.css("a, button").map { |node| node.text.strip }
      assert_includes reply_labels, "HOST Reply wins"
      refute_includes reply_labels, "Reply"
      assert_equal "HOST Reply wins", I18n.t("recording_studio.commentable.common.reply")
    end
  end

  def test_default_english_reply_returns_after_host_override_is_removed
    assert_equal "Reply", I18n.t("recording_studio.commentable.common.reply")

    post user_session_path, params: {
      user: {
        email: @admin.email,
        password: "Password"
      }
    }
    assert_response :redirect

    get all_recording_comments_path(@public_recording)
    assert_response :success
    assert_includes response.body, "Reply"
    refute_includes response.body, "HOST Reply wins"
  end

  private

  # Snapshot load path + Simple backend translations, then restore without a bare
  # I18n.reload! so any store_translations from other tests stay intact.
  def with_restored_i18n_backend
    previous_load_path = I18n.load_path.dup
    previous_translations = i18n_backend_translations_snapshot
    yield
  ensure
    I18n.load_path.replace(previous_load_path)
    restore_i18n_backend_translations(previous_translations) if previous_translations
  end

  def i18n_backend_translations_snapshot
    backend = I18n.backend
    backend.send(:init_translations) unless backend.initialized?
    translations =
      if backend.respond_to?(:translations)
        backend.translations
      else
        backend.instance_variable_get(:@translations)
      end
    return unless translations

    deep_plain_copy(translations)
  end

  def restore_i18n_backend_translations(snapshot)
    backend = I18n.backend
    backend.instance_variable_set(:@translations, snapshot)
    backend.instance_variable_set(:@initialized, true) if backend.instance_variable_defined?(:@initialized)
  end

  def deep_plain_copy(value)
    case value
    when Hash
      value.each_with_object({}) { |(key, nested), copy| copy[key] = deep_plain_copy(nested) }
    when Array
      value.map { |nested| deep_plain_copy(nested) }
    else
      value
    end
  end
end
