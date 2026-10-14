# frozen_string_literal: true

require_relative "../test_helper"

# Behavioral renders: a locale without translations shows loaded / shipped
# English for commentable copy. Uses :de so boot-loaded host English overrides
# and dummy :fr do not interfere with the missing-locale case.
#
# Existing boot override (recording_studio_commentable.host.en.yml) keeps
# common.reply as "HOST Reply" — English assertions note that; never rewrite
# other English tests to expect HOST.
#
# Devise flashes under :de/:fr can say "Translation missing" for their own
# keys; assertions only forbid missing recording_studio.commentable.* text.
class EnglishFallbackTest < ActionDispatch::IntegrationTest
  HOME_TITLE_KEY = "recording_studio.commentable.home.title"
  ADD_COMMENT_KEY = "recording_studio.commentable.common.add_comment"
  COMMENTABLE_MISSING = /translation missing:.*recording_studio\.commentable/i

  setup do
    Rails.application.load_seed
    host! "example.com"

    @admin = User.find_by!(email: "admin@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
    @previous_locales = I18n.available_locales
    I18n.available_locales = (@previous_locales + %i[en de fr]).uniq

    # Force I18n to initialize before store_translations / backend mutations.
    I18n.t(HOME_TITLE_KEY)

    # Sign in under the default locale so Devise flashes stay English and do
    # not pollute commentable missing-key assertions.
    sign_in_admin!
  end

  teardown do
    I18n.locale = I18n.default_locale
    I18n.available_locales = @previous_locales if @previous_locales
  end

  test "missing locale without translations renders gem english on comments pages" do
    I18n.with_locale(:de) do
      refute locale_has_own_translation?(:de, HOME_TITLE_KEY),
             ":de must not ship its own home.title (fallbacks may still resolve via :en)"
      refute locale_has_own_translation?(:de, "recording_studio.commentable.common.comments")

      get "/commentable"
      assert_response :success
      assert_select "h1", text: "All comments"
      refute_match COMMENTABLE_MISSING, @response.body

      # Use a host-absolute path: visiting /commentable mounts SCRIPT_NAME so
      # all_recording_comments_path would incorrectly prefix /commentable.
      get host_all_comments_path
      assert_response :success
      assert_includes @response.body, "Comments"
      assert_includes @response.body, "Post comment"
      assert_includes @response.body, "Write your comment..."
      # Boot-loaded host en override wins for reply via loaded :en fallback.
      assert_includes @response.body, "HOST Reply"
      refute_match COMMENTABLE_MISSING, @response.body
    end
  end

  test "english render matches gem english strings noting HOST Reply override" do
    I18n.with_locale(:en) do
      get "/commentable"
      assert_response :success
      assert_select "h1", text: "All comments"
      assert_includes @response.body, "Every thread in this workspace, in one place."
      refute_match COMMENTABLE_MISSING, @response.body

      get host_all_comments_path
      assert_response :success
      assert_includes @response.body, "Comments"
      assert_includes @response.body, "Post comment"
      assert_includes @response.body, "Write your comment..."
      assert_includes @response.body, "HOST Reply"
      refute_includes @response.body, ">Reply<"
      refute_match COMMENTABLE_MISSING, @response.body

      get host_new_comment_path
      assert_response :success
      assert_includes @response.body, "Add comment"
      assert_includes @response.body, "Post comment"
    end
  end

  test "deleted english home title shows shipped All comments without translation missing" do
    delete_loaded_translation!(:en, HOME_TITLE_KEY)
    delete_loaded_translation!(:fr, HOME_TITLE_KEY)

    refute I18n.exists?(HOME_TITLE_KEY, :en)
    refute I18n.exists?(HOME_TITLE_KEY, :fr)

    previous_raise = ActionView::Helpers::TranslationHelper.raise_on_missing_translations

    [false, true].each do |raise_on_missing|
      ActionView::Helpers::TranslationHelper.raise_on_missing_translations = raise_on_missing

      %i[en fr].each do |locale|
        I18n.with_locale(locale) do
          get "/commentable"

          assert_response :success
          assert_select "h1", text: "All comments"
          refute_match COMMENTABLE_MISSING, @response.body
        end
      end
    end
  ensure
    ActionView::Helpers::TranslationHelper.raise_on_missing_translations = previous_raise
    I18n.reload!
  end

  test "deleted english add comment key shows shipped Add comment on new comment page" do
    delete_loaded_translation!(:en, ADD_COMMENT_KEY)
    delete_loaded_translation!(:fr, ADD_COMMENT_KEY)

    refute I18n.exists?(ADD_COMMENT_KEY, :en)
    refute I18n.exists?(ADD_COMMENT_KEY, :fr)

    previous_raise = ActionView::Helpers::TranslationHelper.raise_on_missing_translations

    [false, true].each do |raise_on_missing|
      ActionView::Helpers::TranslationHelper.raise_on_missing_translations = raise_on_missing

      %i[en fr].each do |locale|
        I18n.with_locale(locale) do
          get host_new_comment_path

          assert_response :success
          assert_includes @response.body, "Add comment"
          refute_match COMMENTABLE_MISSING, @response.body
        end
      end
    end
  ensure
    ActionView::Helpers::TranslationHelper.raise_on_missing_translations = previous_raise
    I18n.reload!
  end

  test "shipped english table becomes a new object after rails reloader reload" do
    before = RecordingStudio::Translation.shipped_english
    refute_empty before
    assert before.key?(HOME_TITLE_KEY)

    previous_cache_classes = Rails.application.config.cache_classes
    # Test env normally keeps cache_classes on; metrics then treats a second
    # register during reload as a duplicate. Flip it off for this reload only.
    Rails.application.config.cache_classes = false
    RecordingStudioMetrics.registry.reset! if defined?(RecordingStudioMetrics)

    Rails.application.reloader.reload!

    after = RecordingStudio::Translation.shipped_english
    refute_same before, after
    assert_equal before, after
    assert_predicate after, :frozen?
  ensure
    Rails.application.config.cache_classes = previous_cache_classes if previous_cache_classes != nil
  end

  test "global I18n config keeps fallbacks load_path available_locales and exception handler" do
    snapshot = i18n_config_snapshot
    gem_en = File.expand_path(RecordingStudioCommentable::Engine.root.join("config/locales/en.yml"))
    boot_en = Rails.root.join("config/locales/recording_studio_commentable.host.en.yml").to_s

    assert_includes snapshot.fetch(:load_path), File.expand_path(gem_en)
    assert_includes snapshot.fetch(:load_path), File.expand_path(boot_en)
    assert_operator snapshot.fetch(:load_path).index(File.expand_path(gem_en)),
                    :<,
                    snapshot.fetch(:load_path).index(File.expand_path(boot_en))
    assert snapshot.fetch(:exception_handler), "expected an I18n exception handler"
    assert_includes snapshot.fetch(:available_locales), :en

    before = i18n_config_snapshot
    RecordingStudio.t(HOME_TITLE_KEY)
    assert_equal before.fetch(:load_path), i18n_config_snapshot.fetch(:load_path)
    assert_equal before.fetch(:exception_handler), i18n_config_snapshot.fetch(:exception_handler)
  end

  # Fails on its own if the engine initializer is removed: asserts the path is
  # already registered from Rails boot. Does not call the initializer block.
  test "boot registers commentable en.yml path without invoking the initializer in the test" do
    expected = File.expand_path(
      RecordingStudioCommentable::Engine.root.join("config/locales/en.yml")
    )
    paths = RecordingStudio::Translation.send(:registered_shipped_english_paths)

    assert_includes paths, expected,
                    "engine boot must register commentable config/locales/en.yml " \
                    "via RecordingStudio::Translation.register_shipped_english"

    initializer = RecordingStudioCommentable::Engine.initializers.find do |entry|
      entry.name == "recording_studio_commentable.register_shipped_english"
    end
    refute_nil initializer
    assert_equal "recording_studio.load_shipped_english", initializer.before
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

  def host_all_comments_path
    "/recordings/#{@public_recording.id}/comments/all"
  end

  def host_new_comment_path
    "/recordings/#{@public_recording.id}/comments/new"
  end

  def i18n_config_snapshot
    {
      load_path: I18n.load_path.map { |path| File.expand_path(path) },
      available_locales: Array(I18n.available_locales).map(&:to_sym).sort,
      exception_handler: I18n.exception_handler,
      enforce_available_locales: I18n.enforce_available_locales,
      fallbacks_class: (I18n.fallbacks.class.name if I18n.respond_to?(:fallbacks))
    }
  end

  def locale_has_own_translation?(locale, full_key)
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    node = I18n.backend.send(:translations)[locale.to_sym]
    return false unless node.is_a?(Hash)

    full_key.split(".").map(&:to_sym).each do |part|
      return false unless node.is_a?(Hash) && node.key?(part)

      node = node[part]
    end
    !node.nil?
  end

  def delete_loaded_translation!(locale, full_key)
    I18n.exists?(full_key, locale)
    parts = full_key.split(".").map(&:to_sym)
    leaf = parts.pop
    translations = I18n.backend.send(:translations)
    locale_key = locale.to_sym
    translations[locale_key] = translations[locale_key].dup if translations[locale_key].frozen?

    node = translations[locale_key]
    parts.each do |part|
      break unless node.is_a?(Hash) && node[part].is_a?(Hash)

      node[part] = node[part].dup if node[part].frozen?
      node = node[part]
    end
    node.delete(leaf) if node.is_a?(Hash)
  end
end
