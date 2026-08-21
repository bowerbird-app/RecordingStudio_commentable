# frozen_string_literal: true

require "test_helper"

class CapabilityTest < Minitest::Test
  PlainModel = Class.new

  class CommentableToModel
    include RecordingStudio::Capabilities::Commentable.to(notify: false)
  end

  class AnotherCommentableToModel
    include RecordingStudio::Capabilities::Commentable.to
  end

  class LegacyCommentableModel
    include RecordingStudioCommentable::Commentable
  end

  def setup
    @original_capabilities = RecordingStudio.configuration.instance_variable_get(:@capabilities).deep_dup
    @original_capability_options = RecordingStudio.configuration.instance_variable_get(:@capability_options).dup
    @original_registered_capabilities = RecordingStudio.registered_capabilities.transform_values(&:dup)
  end

  def teardown
    RecordingStudio.configuration.instance_variable_set(:@capabilities, @original_capabilities)
    RecordingStudio.configuration.instance_variable_set(:@capability_options, @original_capability_options)
    RecordingStudio.instance_variable_set(:@registered_capabilities, @original_registered_capabilities)
  end

  def test_to_wrapper_exists_on_capabilities_commentable
    assert_respond_to RecordingStudio::Capabilities::Commentable, :to
  end

  def test_to_is_a_thin_wrapper_around_include_for
    source = File.read(File.expand_path("../lib/recording_studio_commentable/capability.rb", __dir__))

    assert_includes source, "RecordingStudioCommentable::CommentableOptions.validate!(options)"
    assert_includes source, "RecordingStudio::Capabilities.include_for(:commentable, **options)"
    refute_includes source, "register_capability"
    assert_includes File.read(File.expand_path("../lib/recording_studio_commentable/engine.rb", __dir__)),
                    "RecordingStudio.register_capability("
  end

  def test_to_enables_commentable_and_sets_options
    assert RecordingStudio.capability_enabled?(:commentable, for: CommentableToModel)
    assert_equal({ notify: false }, RecordingStudio.capability_options(:commentable, for: CommentableToModel))
    assert_equal({}, RecordingStudio.capability_options(:commentable, for: AnotherCommentableToModel))
    refute RecordingStudio.capability_enabled?(:commentable, for: PlainModel)
  end

  def test_to_does_not_register_the_capability
    registered_before = RecordingStudio.registered_capabilities.dup

    Class.new do
      def self.name
        "CapabilityTest::RuntimeCommentableModel"
      end

      include RecordingStudio::Capabilities::Commentable.to(notify: true)
    end

    assert_equal registered_before.keys.sort, RecordingStudio.registered_capabilities.keys.sort
    refute_equal({}, RecordingStudio.registered_capabilities) if registered_before.key?(:commentable)
  end

  def test_installing_the_gem_does_not_enable_commentable
    refute RecordingStudio.capability_enabled?(:commentable, for: PlainModel)
    refute RecordingStudio.capability_enabled?(:commentable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:commentable, for: "Workspace")
  end

  def test_legacy_commentable_include_calls_through_to_the_same_path
    assert defined?(RecordingStudioCommentable::Commentable)
    assert RecordingStudio.capability_enabled?(:commentable, for: LegacyCommentableModel)
    assert_equal({}, RecordingStudio.capability_options(:commentable, for: LegacyCommentableModel))
    assert LegacyCommentableModel.include?(RecordingStudioCommentable::Commentable)
  end

  def test_legacy_include_keeps_commentable_predicates
    instance = LegacyCommentableModel.new

    assert_respond_to instance, :commentable?
    assert instance.commentable?
    assert_respond_to LegacyCommentableModel, :commentable?
    assert LegacyCommentableModel.commentable?
  end

  def test_non_commentable_class_does_not_respond_to_commentable
    plain = PlainModel.new
    refute plain.respond_to?(:commentable?), "Plain model should not have commentable?"
  end

  def test_option_validation_stays_in_this_gem
    error = assert_raises(ArgumentError) do
      RecordingStudioCommentable::CommentableOptions.validate!("notify" => true)
    end

    assert_match(/option keys must be symbols/, error.message)
  end
end
