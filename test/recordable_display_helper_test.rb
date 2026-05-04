# frozen_string_literal: true

require "test_helper"

class RecordableDisplayHelperTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioCommentable.instance_variable_get(:@configuration)
    RecordingStudioCommentable.instance_variable_set(:@configuration, RecordingStudioCommentable::Configuration.new)
    @helper = Class.new do
      include RecordingStudioCommentable::RecordableDisplayHelper
    end.new
  end

  def teardown
    RecordingStudioCommentable.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_uses_configured_display_attribute_for_class_name_string
    event_class = Class.new do
      attr_reader :event_name

      def initialize(event_name)
        @event_name = event_name
      end
    end
    Object.const_set("ConfiguredEvent", event_class)

    RecordingStudioCommentable.configuration.recordable_display_attributes = {
      "ConfiguredEvent" => :event_name
    }

    assert_equal "Launch Day", @helper.recordable_display_title(ConfiguredEvent.new("Launch Day"))
  ensure
    Object.send(:remove_const, :ConfiguredEvent) if Object.const_defined?(:ConfiguredEvent)
  end

  def test_accepts_recording_like_wrappers
    page_class = Class.new do
      attr_reader :headline

      def initialize(headline)
        @headline = headline
      end
    end
    Object.const_set("WrappedPage", page_class)

    RecordingStudioCommentable.configuration.recordable_display_attributes = {
      "WrappedPage" => :headline
    }

    wrapper = Struct.new(:recordable).new(WrappedPage.new("Wrapped title"))

    assert_equal "Wrapped title", @helper.recordable_display_title(wrapper)
  ensure
    Object.send(:remove_const, :WrappedPage) if Object.const_defined?(:WrappedPage)
  end

  def test_falls_back_to_title_then_name_then_class_name_when_not_configured
    title_class = Class.new do
      attr_reader :title

      def initialize(title)
        @title = title
      end
    end
    name_class = Class.new do
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
    plain_class = Class.new
    Object.const_set("FallbackTitleThing", title_class)
    Object.const_set("FallbackNameThing", name_class)
    Object.const_set("FallbackPlainThing", plain_class)

    assert_equal "Example title", @helper.recordable_display_title(FallbackTitleThing.new("  Example title  "))
    assert_equal "Folder name", @helper.recordable_display_title(FallbackNameThing.new(" Folder name "))
    assert_equal "FallbackPlainThing", @helper.recordable_display_title(FallbackPlainThing.new)
  ensure
    Object.send(:remove_const, :FallbackTitleThing) if Object.const_defined?(:FallbackTitleThing)
    Object.send(:remove_const, :FallbackNameThing) if Object.const_defined?(:FallbackNameThing)
    Object.send(:remove_const, :FallbackPlainThing) if Object.const_defined?(:FallbackPlainThing)
  end

  def test_returns_missing_value_when_recordable_is_missing
    assert_equal "Missing recordable", @helper.recordable_display_title(nil, missing: "Missing recordable")
  end

  def test_tolerates_legacy_configuration_without_display_attribute_accessor
    legacy_config = Class.new do
      attr_accessor :timeout

      def initialize
        @timeout = 5
      end

      def rich_text_comments
        false
      end
    end.new

    RecordingStudioCommentable.instance_variable_set(:@configuration, legacy_config)

    name_class = Class.new do
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end
    Object.const_set("LegacyConfigThing", name_class)

    assert_equal "Legacy name", @helper.recordable_display_title(LegacyConfigThing.new("Legacy name"))
  ensure
    Object.send(:remove_const, :LegacyConfigThing) if Object.const_defined?(:LegacyConfigThing)
  end
end
