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
    "recording_studio.commentable.button.comments.one" => "%{count} Comment",
    "recording_studio.commentable.button.comments.other" => "%{count} Comments"
  }.freeze

  def setup
    locale_path = File.join(engine_locales_dir, "en.yml")
    I18n.load_path |= [locale_path]
    I18n.backend.load_translations
  end

  def test_engine_ships_only_english_locale_files
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  def test_engine_initializer_appends_locale_files_to_i18n_load_path
    engine_source = File.read(File.expand_path("../lib/recording_studio_commentable/engine.rb", __dir__))

    assert_includes engine_source, 'initializer "recording_studio_commentable.locales"'
    assert_includes engine_source, "app.config.i18n.load_path"
    assert_includes engine_source, 'root.glob("config/locales/**/*.{rb,yml}")'
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
    assert_equal "%{count} Comment", tree.fetch("button").fetch("comments").fetch("one")
    assert_equal "%{count} Comments", tree.fetch("button").fetch("comments").fetch("other")
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

  def engine_locales_dir
    File.expand_path("../config/locales", __dir__)
  end

  def locale_tree(path, locale)
    YAML.safe_load_file(path, aliases: true).fetch(locale)
  end
end
