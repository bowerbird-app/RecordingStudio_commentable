# frozen_string_literal: true

require "test_helper"

class AccessiblePinTest < ActiveSupport::TestCase
  def test_root_and_dummy_gemfiles_pin_accessible_v0_54_0
    root = File.expand_path("..", __dir__)

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      assert_includes contents, 'gem "recording_studio_accessible"'
      assert_includes contents, 'tag: "v0.54.0"', "#{path} should pin Accessible v0.54.0"
      refute_match(
        /gem "recording_studio_accessible".*tag: "v0\.24\./,
        contents,
        "#{path} should not keep the prior Accessible pin"
      )
      refute_includes contents, 'tag: "v0.22.2"', "#{path} should not keep the prior Accessible pin"
      assert_includes contents, 'gem "recording_studio_trashable"'
      assert_includes contents, 'tag: "v1.2.0"', "#{path} should pin Trashable v1.2.0"
      refute_includes contents, 'tag: "v0.12.3"', "#{path} should not keep the prior Trashable pin"
      assert_includes contents, 'gem "recording_studio_metrics"'
      assert_includes contents, 'tag: "v0.9.1"', "#{path} should pin Metrics v0.9.1"
      refute_includes contents, 'tag: "v0.7.3"', "#{path} should not keep the prior Metrics pin"
    end
  end

  def test_root_and_dummy_gemfiles_pin_core_7_companions
    root = File.expand_path("..", __dir__)
    pins = {
      'gem "recording_studio_api"' => 'tag: "v1.15.0"',
      'gem "recording_studio_admin"' => 'tag: "v2.19.0"',
      'gem "recording_studio_moveable"' => 'tag: "v6.0.1"',
      'gem "recording_studio_icons"' => 'tag: "v0.4.1"',
      'gem "recording_studio_logs"' => 'tag: "v0.8.1"',
      'gem "puma", "8.1.0"' => nil
    }

    [File.join(root, "Gemfile"), File.join(root, "test/dummy/Gemfile")].each do |path|
      contents = File.read(path)
      pins.each do |gem_line, tag|
        assert_includes contents, gem_line, path
        assert_includes contents, tag, path if tag
      end
    end

    dummy = File.read(File.join(root, "test/dummy/Gemfile"))
    assert_includes dummy, 'gem "msgpack", ">= 1.8.7"'
  end
end
