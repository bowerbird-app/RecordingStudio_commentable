# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioCommentable.instance_variable_get(:@configuration)
    RecordingStudioCommentable.instance_variable_set(:@configuration, RecordingStudioCommentable::Configuration.new)
  end

  def teardown
    RecordingStudioCommentable.configuration.hooks.clear!
    RecordingStudioCommentable.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_engine_registers_component_path_for_autoloading
    component_paths = RecordingStudioCommentable::Engine.paths["app/components"].existent

    assert_includes component_paths, File.expand_path("../app/components", __dir__)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioCommentable.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioCommentable.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_commentable.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_commentable.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioCommentable.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_commentable).new(
      {
        timeout: 12,
        use_recording_studio_trashable_for_destroy: true,
        layout: "flat_pack_pseudo_top_nav",
        rich_text_comments: :selection,
        recordable_display_attributes: { "Event" => :event_name },
        author_display_attributes: { "User" => :full_name },
        author_avatar_attributes: { "User" => :avatar_url }
      }
    )
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        {
          timeout: 12,
          use_recording_studio_trashable_for_destroy: false,
          layout: "host_comment_shell",
          rich_text_comments: :toolbar,
          recordable_display_attributes: { "Page" => :title },
          author_display_attributes: { "SystemActor" => :display_name },
          author_avatar_attributes: { "SystemActor" => :avatar_url }
        }
      end
    end.new(app_config)

    find_initializer("recording_studio_commentable.load_config").block.call(app)

    assert hook_called
    assert_equal RecordingStudioCommentable.configuration, hook_payload
    assert_equal 12, RecordingStudioCommentable.configuration.timeout
    assert_equal true, RecordingStudioCommentable.configuration.use_recording_studio_trashable_for_destroy
    assert_equal "flat_pack_pseudo_top_nav", RecordingStudioCommentable.configuration.layout
    assert_equal :selection, RecordingStudioCommentable.configuration.rich_text_comments
    assert_equal({ "Event" => :event_name }, RecordingStudioCommentable.configuration.recordable_display_attributes)
    assert_equal({ "User" => :full_name }, RecordingStudioCommentable.configuration.author_display_attributes)
    assert_equal({ "User" => :avatar_url }, RecordingStudioCommentable.configuration.author_avatar_attributes)
  end

  def test_load_config_handles_errors_and_each_pair_fallback
    pair_config = Class.new do
      def each_pair
        yield(:timeout, 15)
        yield(:use_recording_studio_trashable_for_destroy, true)
        yield(:layout, "flat_pack_pseudo_top_nav")
        yield(:rich_text_comments, "selection")
        yield(:recordable_display_attributes, { Page: :title })
        yield(:author_display_attributes, { User: :full_name })
        yield(:author_avatar_attributes, { User: :avatar_url })
      end
    end.new

    xcfg = Struct.new(:recording_studio_commentable).new(pair_config)
    app_config = Struct.new(:x).new(xcfg)

    app = Struct.new(:config) do
      def config_for(_name)
        raise "missing file"
      end
    end.new(app_config)

    find_initializer("recording_studio_commentable.load_config").block.call(app)

    assert_equal 15, RecordingStudioCommentable.configuration.timeout
    assert_equal true, RecordingStudioCommentable.configuration.use_recording_studio_trashable_for_destroy
    assert_equal "flat_pack_pseudo_top_nav", RecordingStudioCommentable.configuration.layout
    assert_equal :selection, RecordingStudioCommentable.configuration.rich_text_comments
    assert_equal({ "Page" => :title }, RecordingStudioCommentable.configuration.recordable_display_attributes)
    assert_equal({ "User" => :full_name }, RecordingStudioCommentable.configuration.author_display_attributes)
    assert_equal({ "User" => :avatar_url }, RecordingStudioCommentable.configuration.author_avatar_attributes)
  end

  def test_load_config_swallow_each_pair_errors
    bad_pair_config = Class.new do
      def each_pair
        raise "bad pair"
      end
    end.new

    xcfg = Struct.new(:recording_studio_commentable).new(bad_pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { timeout: 5, use_recording_studio_trashable_for_destroy: false, layout: nil, rich_text_comments: false }
      end
    end.new(app_config)

    # Should not raise even if xcfg.each_pair fails.
    find_initializer("recording_studio_commentable.load_config").block.call(app)

    assert_equal 5, RecordingStudioCommentable.configuration.timeout
    assert_equal false, RecordingStudioCommentable.configuration.use_recording_studio_trashable_for_destroy
    assert_nil RecordingStudioCommentable.configuration.layout
    assert_equal false, RecordingStudioCommentable.configuration.rich_text_comments
  end

  def test_apply_extension_initializers_register_active_support_on_load_callbacks
    to_prepare_blocks = []
    config_stub = Object.new
    config_stub.define_singleton_method(:to_prepare) do |&block|
      to_prepare_blocks << block
    end

    RecordingStudioCommentable::Engine.stub(:config, config_stub) do
      find_initializer("recording_studio_commentable.apply_model_extensions").block.call
      find_initializer("recording_studio_commentable.apply_controller_extensions").block.call
    end

    assert_equal 2, to_prepare_blocks.size
  end

  def test_apply_model_extensions_adds_registered_methods_once
    model_class = Class.new do
      def self.name
        "ExampleRecord"
      end
    end

    RecordingStudioCommentable.configuration.hooks.extend_model(:ExampleRecord) do
      def commentable_extension_method
        :applied
      end
    end

    RecordingStudioCommentable::Engine.apply_model_extensions(model_class)
    RecordingStudioCommentable::Engine.apply_model_extensions(model_class)

    instance = model_class.new
    assert_equal :applied, instance.commentable_extension_method
  end

  def test_apply_controller_extensions_matches_demodulized_name
    controller_class = Class.new do
      def self.name
        "Admin::DashboardController"
      end
    end

    RecordingStudioCommentable.configuration.hooks.extend_controller(:DashboardController) do
      def commentable_controller_extension
        :applied
      end
    end

    RecordingStudioCommentable::Engine.apply_controller_extensions(controller_class)

    instance = controller_class.new
    assert_equal :applied, instance.commentable_controller_extension
  end

  private

  def find_initializer(name)
    RecordingStudioCommentable::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
