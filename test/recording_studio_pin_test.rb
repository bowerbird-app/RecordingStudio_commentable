# frozen_string_literal: true

require "test_helper"

class RecordingStudioPinTest < ActiveSupport::TestCase
  def test_root_and_dummy_gemfiles_pin_recording_studio_v4_6_0
    root = File.expand_path("..", __dir__)

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      assert_match(
        %r{gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v4\.6\.0"},
        contents,
        "#{path} should pin Recording Studio v4.6.0"
      )
      refute_includes contents, 'tag: "v4.5.0"', "#{path} should not keep the prior Recording Studio pin"
    end
  end
end
