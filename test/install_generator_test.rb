# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "generators/recording_studio_commentable/install/install_generator"

class InstallGeneratorTest < Minitest::Test
  def with_temp_app
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "app/assets/tailwind"))
      yield dir
    end
  end

  def build_generator(destination_root, options = {})
    RecordingStudioCommentable::Generators::InstallGenerator.new(
      [],
      options,
      destination_root: destination_root
    )
  end

  def test_mount_engine_uses_configured_mount_path
    generator = build_generator("/tmp", mount_path: "/addons/commentable")
    routes = []

    generator.stub(:route, ->(value) { routes << value }) do
      generator.mount_engine
    end

    assert_equal ["mount RecordingStudioCommentable::Engine, at: \"/addons/commentable\""], routes
  end

  def test_add_tailwind_source_injects_engine_and_flatpack_sources
    with_temp_app do |dir|
      css_path = File.join(dir, "app/assets/tailwind/application.css")
      File.write(css_path, "@import \"tailwindcss\";\n")

      generator = build_generator(dir)

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, nil) do
          generator.add_tailwind_source
        end
      end

      css = File.read(css_path)
      assert_tailwind_sources_present(css)
    end
  end

  def test_add_tailwind_source_does_not_duplicate_existing_entries
    with_temp_app do |dir|
      css_path = File.join(dir, "app/assets/tailwind/application.css")
      File.write(css_path, <<~CSS)
        @import "tailwindcss";
        @source "../../vendor/bundle/**/recording_studio_commentable/app/views/**/*.erb";
        @source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/recording_studio_commentable-*/app/views/**/*.erb";
        @source "../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}";
        @source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/flatpack-*/app/components/**/*.{rb,erb}";
      CSS

      generator = build_generator(dir)

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, nil) do
          generator.add_tailwind_source
        end
      end

      css = File.read(css_path)
      assert_tailwind_sources_present(css)
      assert_tailwind_sources_count(css, 1)
    end
  end

  def test_copy_initializer_sets_rich_text_comments_default_off
    with_temp_app do |dir|
      generator = build_generator(dir)

      generator.copy_initializer

      initializer = File.read(File.join(dir, "config/initializers/recording_studio_commentable.rb"))
      assert_includes initializer, "config.use_recording_studio_trashable_for_destroy = false"
      assert_includes initializer, "config.rich_text_comments = false"
      assert_includes initializer, "Comment editor mode: false, :toolbar, or :selection"
      assert_includes initializer, "config.recordable_display_attributes = {}"
      assert_includes initializer, "config.author_display_attributes = {}"
      assert_includes initializer, "config.author_avatar_attributes = {}"
    end
  end

  private

  def assert_tailwind_sources_present(css)
    tailwind_source_lines.each do |line|
      assert_includes css, line
    end
  end

  def assert_tailwind_sources_count(css, count)
    tailwind_source_lines.each do |line|
      assert_equal count, css.scan(line).size
    end
  end

  def tailwind_source_lines
    [
      '@source "../../vendor/bundle/**/recording_studio_commentable/app/views/**/*.erb";',
      '@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/recording_studio_commentable-*/app/views/**/*.erb";',
      '@source "../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}";',
      '@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/flatpack-*/app/components/**/*.{rb,erb}";'
    ]
  end
end
