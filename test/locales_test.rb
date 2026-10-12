# frozen_string_literal: true

require "test_helper"
require "yaml"
require "i18n"

class LocalesTest < Minitest::Test
  EXPECTED_LEAVES = {
    "recording_studio.commentable.layout.title" => "RecordingStudio Commentable",
    "recording_studio.commentable.layout.application_name" => "RecordingStudio Commentable",
    "recording_studio.commentable.navigation.go_back" => "Go back",
    "recording_studio.commentable.navigation.close" => "Close",
    "recording_studio.commentable.common.cancel" => "Cancel",
    "recording_studio.commentable.common.reply" => "Reply",
    "recording_studio.commentable.common.comments" => "Comments",
    "recording_studio.commentable.common.add_comment" => "Add comment",
    "recording_studio.commentable.common.edit_comment" => "Edit comment",
    "recording_studio.commentable.common.anonymous" => "Anonymous",
    "recording_studio.commentable.common.you" => "You",
    "recording_studio.commentable.home.title" => "All comments",
    "recording_studio.commentable.home.subtitle" => "Every thread in this workspace, in one place.",
    "recording_studio.commentable.index.subtitle" => "Leave a note, or just read along.",
    "recording_studio.commentable.empty.title" => "No comments yet",
    "recording_studio.commentable.empty.body" => "Be the first to leave a comment.",
    "recording_studio.commentable.feed.loading_more" => "Loading more comments...",
    "recording_studio.commentable.feed.load_more" => "Load more",
    "recording_studio.commentable.comment.hidden" => "Comment hidden",
    "recording_studio.commentable.composer.placeholder" => "Write your comment...",
    "recording_studio.commentable.composer.post" => "Post comment",
    "recording_studio.commentable.composer.save" => "Save changes",
    # I18n pluralization tokens use %{count}, not Ruby format annotations.
    "recording_studio.commentable.button.comments.one" => "%{count} Comment", # rubocop:disable Style/FormatStringToken
    "recording_studio.commentable.button.comments.other" => "%{count} Comments", # rubocop:disable Style/FormatStringToken
    "recording_studio.commentable.flashes.comment_added" => "Comment added.",
    "recording_studio.commentable.flashes.comment_updated" => "Comment updated.",
    "recording_studio.commentable.flashes.comment_deleted" => "Comment deleted.",
    "recording_studio.commentable.flashes.recording_not_found" => "Recording not found.",
    "recording_studio.commentable.flashes.comment_not_found" => "Comment not found.",
    "recording_studio.commentable.flashes.comments_not_enabled" => "Comments are not enabled for this resource.",
    "recording_studio.commentable.flashes.not_allowed_view" => "You are not allowed to view comments here.",
    "recording_studio.commentable.flashes.not_allowed_post" => "You are not allowed to post comments here.",
    "recording_studio.commentable.flashes.not_allowed_edit" => "You are not allowed to edit this comment.",
    "recording_studio.commentable.flashes.must_sign_in" => "You must be signed in.",
    "recording_studio.commentable.errors.body_blank" => "Body cannot be blank",
    "recording_studio.commentable.errors.comment_invalid" => "Comment is invalid",
    "recording_studio.commentable.display.missing_recordable" => "Missing recordable",
    "recording_studio.commentable.display.unknown_item" => "Unknown item"
  }.freeze

  def setup
    seed_gem_english_translations!
  end

  def test_engine_ships_only_english_locale_files
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  def test_engine_does_not_reappend_locales_to_i18n_load_path
    engine_source = File.read(File.expand_path("../lib/recording_studio_commentable/engine.rb", __dir__))

    refute_includes engine_source, 'initializer "recording_studio_commentable.locales"'
    refute_includes engine_source, "app.config.i18n.load_path"
  end

  def test_lib_ruby_files_do_not_mention_i18n_load_path
    lib_root = File.expand_path("../lib", __dir__)
    ruby_files = Dir[File.join(lib_root, "**", "*.rb")]

    assert_operator ruby_files.size, :>, 0

    ruby_files.each do |path|
      source = File.read(path)
      refute_includes source, "i18n.load_path", "#{path} must not mention i18n.load_path"
      refute_includes source, "I18n.load_path", "#{path} must not mention I18n.load_path"
    end
  end

  def test_english_keys_resolve_without_missing_translations
    I18n.with_locale(:en) do
      EXPECTED_LEAVES.each do |full_key, english|
        translation = I18n.t(full_key, default: nil)

        assert_equal english, translation, "#{full_key} should resolve to #{english.inspect}"
        assert_equal english, I18n.t(full_key, raise: true)
      end
    end
  end

  def test_button_comments_pluralization_matches_previous_english
    I18n.with_locale(:en) do
      assert_equal "0 Comments", I18n.t("recording_studio.commentable.button.comments", count: 0)
      assert_equal "1 Comment", I18n.t("recording_studio.commentable.button.comments", count: 1)
      assert_equal "3 Comments", I18n.t("recording_studio.commentable.button.comments", count: 3)
      assert_equal "12 Comments", I18n.t("recording_studio.commentable.button.comments", count: 12)
    end
  end

  def test_en_yml_nests_keys_under_recording_studio_commentable
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
           .fetch("recording_studio")
           .fetch("commentable")

    assert_equal "Go back", tree.fetch("navigation").fetch("go_back")
    assert_equal "All comments", tree.fetch("home").fetch("title")
    assert_equal "Write your comment...", tree.fetch("composer").fetch("placeholder")
    assert_equal "Comment added.", tree.fetch("flashes").fetch("comment_added")
    assert_equal "Body cannot be blank", tree.fetch("errors").fetch("body_blank")
    comments = tree.fetch("button").fetch("comments")
    assert_equal EXPECTED_LEAVES.fetch("recording_studio.commentable.button.comments.one"), comments.fetch("one")
    assert_equal EXPECTED_LEAVES.fetch("recording_studio.commentable.button.comments.other"), comments.fetch("other")
  end

  def test_yaml_boolean_looking_keys_are_quoted_when_present
    raw = File.read(File.join(engine_locales_dir, "en.yml"))
    boolean_looking = raw.scan(/^\s*((?:yes|no|on|off|true|false|null)):/i).flatten

    boolean_looking.each do |key|
      assert_match(/["']#{Regexp.escape(key)}["']:/, raw,
                   "YAML key #{key.inspect} must be quoted so Psych does not coerce it")
    end
  end

  def test_gemspec_does_not_depend_on_internationalization
    gemspec = File.read(File.expand_path("../recording_studio_commentable.gemspec", __dir__))

    refute_includes gemspec, "recording_studio_internationalization"
    refute_includes gemspec, "RecordingStudio_Internationalization"
  end

  def test_dummy_gemfile_does_not_depend_on_internationalization
    dummy_gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    refute_includes dummy_gemfile, "recording_studio_internationalization"
    refute_includes dummy_gemfile, "RecordingStudio_Internationalization"
  end

  private

  def seed_gem_english_translations!
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
    I18n.backend.store_translations(:en, tree)
  end

  def engine_locales_dir
    File.expand_path("../config/locales", __dir__)
  end

  def locale_tree(path, locale)
    YAML.safe_load_file(path, aliases: true).fetch(locale)
  end
end
