# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def teardown
    RecordingStudioCommentable.instance_variable_set(:@configuration, nil)
  end

  def setup
    @configuration = RecordingStudioCommentable::Configuration.new
  end

  def test_merge_updates_known_attributes
    @configuration.merge!(timeout: 9, rich_text_comments: true)

    assert_equal 9, @configuration.timeout
    assert_equal true, @configuration.rich_text_comments
  end

  def test_merge_ignores_unknown_keys
    @configuration.merge!(unknown_key: "ignored", timeout: 7, rich_text_comments: true)

    refute_respond_to @configuration, :unknown_key
    assert_equal 7, @configuration.timeout
    assert_equal true, @configuration.rich_text_comments
  end

  def test_merge_with_non_enumerable_is_noop
    original = @configuration.to_h

    @configuration.merge!(nil)

    assert_equal original[:timeout], @configuration.timeout
    assert_equal original[:rich_text_comments], @configuration.rich_text_comments
  end

  def test_defaults_rich_text_comments_to_false
    assert_equal false, @configuration.rich_text_comments
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

  def test_configuration_upgrades_legacy_instance_missing_new_accessors
    legacy_config = Class.new do
      attr_accessor :timeout
      attr_reader :hooks

      def initialize
        @timeout = 11
        @hooks = RecordingStudioCommentable::Hooks.new
      end
    end.new

    RecordingStudioCommentable.instance_variable_set(:@configuration, legacy_config)

    upgraded = RecordingStudioCommentable.configuration

    assert_kind_of RecordingStudioCommentable::Configuration, upgraded
    assert_equal 11, upgraded.timeout
    assert_equal false, upgraded.rich_text_comments
    assert_same legacy_config.hooks, upgraded.hooks
  end
end
