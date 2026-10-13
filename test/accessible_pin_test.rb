# frozen_string_literal: true

require "test_helper"

class AccessiblePinTest < ActiveSupport::TestCase
  def test_root_and_dummy_gemfiles_pin_accessible_v0_17_0
    root = File.expand_path("..", __dir__)

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      assert_includes contents, 'gem "recording_studio_accessible"'
      assert_includes contents, 'tag: "v0.17.0"', "#{path} should pin Accessible v0.17.0"
      refute_includes contents, 'tag: "v0.15.0"', "#{path} should not keep the prior Accessible pin"
      assert_includes contents, 'gem "recording_studio_trashable"'
      assert_includes contents, 'tag: "v0.10.0"', "#{path} should pin Trashable v0.10.0"
      assert_includes contents, 'gem "recording_studio_metrics"'
      assert_includes contents, 'tag: "v0.2.0"', "#{path} should pin Metrics v0.2.0"
    end
  end
end
