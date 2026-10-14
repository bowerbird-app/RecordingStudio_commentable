# frozen_string_literal: true

require "test_helper"

class RecordingStudioPinTest < ActiveSupport::TestCase
  def test_root_and_dummy_gemfiles_pin_recording_studio_v4_7_0
    root = File.expand_path("..", __dir__)

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      assert_match(
        %r{gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4\.7\.0"},
        contents,
        "#{path} should pin Recording Studio v4.7.0"
      )
      refute_includes contents, 'tag: "v4.6.0"', "#{path} should not keep the prior Recording Studio pin"
    end
  end

  def test_gemspec_depends_on_recording_studio_tilde_4_7
    gemspec = File.read(File.expand_path("../recording_studio_commentable.gemspec", __dir__))

    assert_match(
      /spec\.add_dependency ["']recording_studio["'], ["']~> 4\.7["']/,
      gemspec,
      "gemspec must depend on recording_studio ~> 4.7"
    )
    refute_includes gemspec, '">= 4.7.0"'
  end
end
