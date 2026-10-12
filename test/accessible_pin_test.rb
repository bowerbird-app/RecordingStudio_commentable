# frozen_string_literal: true

require "test_helper"

class AccessiblePinTest < ActiveSupport::TestCase
  def test_root_and_dummy_gemfiles_pin_accessible_v0_15_0
    root = File.expand_path("..", __dir__)

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      assert_includes contents, 'gem "recording_studio_accessible"'
      assert_includes contents, 'tag: "v0.15.0"', "#{path} should pin Accessible v0.15.0"
      refute_includes contents, 'tag: "v0.13.0"', "#{path} should not keep the prior Accessible pin"
    end

    assert_equal "0.15.0", RecordingStudioAccessible::VERSION
  end
end
