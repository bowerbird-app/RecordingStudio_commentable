# frozen_string_literal: true

require "test_helper"

class RecordingStudioPinTest < ActiveSupport::TestCase
  def test_root_and_dummy_gemfiles_pin_recording_studio_v6_3_0
    root = File.expand_path("..", __dir__)

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      assert_match(
        %r{gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v6\.3\.0"},
        contents,
        "#{path} should pin Recording Studio v6.3.0"
      )
      refute_includes contents, 'tag: "v4.7.0"', "#{path} should not keep the prior Recording Studio pin"
    end
  end

  def test_gemspec_depends_on_recording_studio_6_1_0
    gemspec = File.read(File.expand_path("../recording_studio_commentable.gemspec", __dir__))

    assert_match(
      /spec\.add_dependency ["']recording_studio["'], ["']>= 6\.1\.0["']/,
      gemspec,
      "gemspec must depend on recording_studio >= 6.1.0"
    )
    refute_includes gemspec, '"~> 4.7"'
    refute_includes gemspec, '">= 4.2"'
    refute_includes gemspec, '"< 7"'
  end

  def test_root_and_dummy_gemfiles_pin_flat_pack_v0_1_329
    root = File.expand_path("..", __dir__)
    dummy = File.read(File.join(root, "test/dummy/Gemfile"))
    gemfile = File.read(File.join(root, "Gemfile"))

    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.329"'
    assert_includes dummy, 'github: "bowerbird-app/flatpack", tag: "v0.1.329"'
    refute_includes dummy, 'github: "bowerbird-app/flatpack", branch: "main"'
    refute_includes gemfile, 'tag: "v0.1.208"'
  end
end
