# frozen_string_literal: true

require "test_helper"

class AccessiblePinTest < ActiveSupport::TestCase
  def test_root_and_dummy_gemfiles_pin_accessible_v0_24_2
    root = File.expand_path("..", __dir__)

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      assert_includes contents, 'gem "recording_studio_accessible"'
      assert_includes contents, 'tag: "v0.24.2"', "#{path} should pin Accessible v0.24.2"
      refute_includes contents, 'tag: "v0.24.0"', "#{path} should not keep the prior Accessible pin"
      refute_includes contents, 'tag: "v0.22.2"', "#{path} should not keep the prior Accessible pin"
      assert_includes contents, 'gem "recording_studio_trashable"'
      assert_includes contents, 'tag: "v0.12.3"', "#{path} should pin Trashable v0.12.3"
      refute_includes contents, 'tag: "v0.12.2"', "#{path} should not keep the prior Trashable pin"
      assert_includes contents, 'gem "recording_studio_metrics"'
      assert_includes contents, 'tag: "v0.7.3"', "#{path} should pin Metrics v0.7.3"
      refute_includes contents, 'tag: "v0.7.2"', "#{path} should not keep the prior Metrics pin"
    end
  end
end
