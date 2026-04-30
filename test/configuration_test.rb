# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioCommentable::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(timeout: 9)

    assert_equal 9, @configuration.timeout
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", timeout: 7)

    refute_respond_to @configuration, :unknown_key
    assert_equal 7, @configuration.timeout
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_equal original[:timeout], @configuration.timeout
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_equal 2, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioCommentable.configure

    assert_kind_of RecordingStudioCommentable::Configuration, RecordingStudioCommentable.configuration
  end
end
