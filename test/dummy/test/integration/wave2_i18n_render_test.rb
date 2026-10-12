# frozen_string_literal: true

require_relative "../test_helper"

# Render-level literal-English asserts for wave 2 non-view copy (alongside
# comments_pages_flow_test source greps). English output must match main.
class Wave2I18nRenderTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
  end

  def test_new_comment_page_renders_literal_english_add_comment_heading
    sign_in_admin!

    get new_recording_comment_path(@public_recording)
    assert_response :success
    assert_includes response.body, "Add comment"
    assert_includes response.body, "Post comment"
  end

  def test_create_comment_flash_renders_literal_english_comment_added
    sign_in_admin!

    post recording_comments_path(@public_recording), params: {
      comment: { body: "Wave2 flash create body" }
    }
    assert_redirected_to all_recording_comments_path(@public_recording, anchor: "root")
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Comment added."
    assert_includes response.body, "Wave2 flash create body"
  end

  def test_blank_body_service_error_renders_literal_english_on_new_form
    sign_in_admin!

    post recording_comments_path(@public_recording), params: {
      comment: { body: "" }
    }
    assert_response :unprocessable_entity
    assert_includes response.body, "Body cannot be blank"
    assert_includes response.body, "Add comment"
  end

  def test_anonymous_display_name_english_matches_main_constant
    comment = RecordingStudioCommentable::Comment.new(body: "anon", author: nil)

    assert_equal RecordingStudioCommentable::Comment::ANONYMOUS_DISPLAY_NAME, comment.author_display_name
    assert_equal "Anonymous", comment.author_display_name
  end

  def test_anonymous_display_name_follows_non_english_locale_with_fallback
    comment = RecordingStudioCommentable::Comment.new(body: "anon", author: nil)

    with_restored_i18n_backend do
      previous_locales = I18n.available_locales
      I18n.available_locales = (previous_locales + [:fr]).uniq
      I18n.backend.store_translations(:fr, {
        recording_studio: {
          commentable: {
            common: {
              anonymous: "Anonyme"
            }
          }
        }
      })

      I18n.with_locale(:fr) do
        assert_equal "Anonyme", comment.author_display_name
      end
    ensure
      I18n.available_locales = previous_locales if defined?(previous_locales) && previous_locales
    end
  end

  def test_service_error_string_type_english_details_match_main
    result = RecordingStudioCommentable::Services::CreateComment.call(
      parent_recording: @public_recording,
      body: "",
      author: @admin
    )

    assert result.failure?
    assert_equal "Body cannot be blank", result.error

    comment = RecordingStudioCommentable::Comment.new(body: "")
    comment.errors.add(:base, result.error)

    assert_equal [{ error: "Body cannot be blank" }], comment.errors.details[:base]
    assert_includes comment.errors.full_messages, "Body cannot be blank"
  end

  def test_service_error_string_type_translates_in_french_and_hosts_override
    with_restored_i18n_backend do
      previous_locales = I18n.available_locales
      I18n.available_locales = (previous_locales + [:fr]).uniq
      I18n.backend.store_translations(:fr, {
        recording_studio: {
          commentable: {
            errors: {
              body_blank: "Le corps ne peut pas être vide"
            }
          }
        }
      })
      I18n.backend.store_translations(:en, {
        recording_studio: {
          commentable: {
            errors: {
              body_blank: "HOST Body cannot be blank"
            }
          }
        }
      })

      I18n.with_locale(:fr) do
        result = RecordingStudioCommentable::Services::CreateComment.call(
          parent_recording: @public_recording,
          body: "",
          author: @admin
        )
        assert_equal "Le corps ne peut pas être vide", result.error

        comment = RecordingStudioCommentable::Comment.new(body: "")
        comment.errors.add(:base, result.error)
        assert_equal [{ error: "Le corps ne peut pas être vide" }], comment.errors.details[:base]
        assert_includes comment.errors.full_messages, "Le corps ne peut pas être vide"
      end

      I18n.with_locale(:en) do
        result = RecordingStudioCommentable::Services::CreateComment.call(
          parent_recording: @public_recording,
          body: "",
          author: @admin
        )
        assert_equal "HOST Body cannot be blank", result.error
      end
    ensure
      I18n.available_locales = previous_locales if defined?(previous_locales) && previous_locales
    end
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
