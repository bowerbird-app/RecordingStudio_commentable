# frozen_string_literal: true

module RecordingStudioCommentable
  # Hook system for extending engine behavior from host applications.
  #
  # This module provides a registry for lifecycle hooks, service hooks,
  # and extension points that allow host applications to customize
  # engine behavior without modifying source code.
  #
  # @example Registering hooks
  #   RecordingStudioCommentable.configuration.hooks.after_initialize do
  #     Rails.logger.info "RecordingStudioCommentable initialized!"
  #   end
  #
  class Hooks
    # Error raised when a hook fails and raise_on_error is enabled
    class HookError < StandardError; end

    # Default priority for hooks (lower runs first)
    DEFAULT_PRIORITY = 100

    attr_accessor :raise_on_error

    def initialize
      @registry = Hash.new { |h, k| h[k] = [] }
      @model_extensions = Hash.new { |h, k| h[k] = [] }
      @controller_extensions = Hash.new { |h, k| h[k] = [] }
      @raise_on_error = false
      @mutex = Mutex.new
    end

    def before_initialize(handler = nil, priority: DEFAULT_PRIORITY, &)
      register(:before_initialize, handler, priority: priority, &)
    end

    def after_initialize(handler = nil, priority: DEFAULT_PRIORITY, &)
      register(:after_initialize, handler, priority: priority, &)
    end

    def on_configuration(handler = nil, priority: DEFAULT_PRIORITY, &)
      register(:on_configuration, handler, priority: priority, &)
    end

    def before_service(handler = nil, priority: DEFAULT_PRIORITY, &)
      register(:before_service, handler, priority: priority, &)
    end

    def after_service(handler = nil, priority: DEFAULT_PRIORITY, &)
      register(:after_service, handler, priority: priority, &)
    end

    def around_service(handler = nil, priority: DEFAULT_PRIORITY, &)
      register(:around_service, handler, priority: priority, &)
    end

    def on(event_name, handler = nil, priority: DEFAULT_PRIORITY, &)
      register(event_name, handler, priority: priority, &)
    end

    def extend_model(model_name, &block)
      return unless block_given?

      @mutex.synchronize do
        @model_extensions[model_name.to_sym] << block
      end
    end

    def extend_controller(controller_name, &block)
      return unless block_given?

      @mutex.synchronize do
        @controller_extensions[controller_name.to_sym] << block
      end
    end

    def model_extensions_for(model_name)
      extensions_for(@model_extensions, model_name)
    end

    def controller_extensions_for(controller_name)
      extensions_for(@controller_extensions, controller_name)
    end

    def run(event_name, *args)
      hooks = @registry[event_name].sort_by { |h| h[:priority] }
      results = []

      hooks.each do |hook|
        result = execute_hook(hook[:handler], *args)
        results << result
      rescue StandardError => e
        handle_hook_error(e, event_name, hook)
      end

      results
    end

    def run_around(event_name, context, &block)
      hooks = @registry[event_name].sort_by { |h| h[:priority] }

      if hooks.empty?
        yield
      else
        chain = hooks.reverse.reduce(block) do |next_block, hook|
          proc { execute_hook(hook[:handler], context, next_block) }
        end
        chain.call
      end
    end

    def registered?(event_name)
      @registry[event_name].any?
    end

    def registered_events
      @registry.transform_values(&:size)
    end

    def clear!
      @mutex.synchronize do
        @registry.clear
        @model_extensions.clear
        @controller_extensions.clear
      end
    end

    def clear(event_name)
      @mutex.synchronize do
        @registry.delete(event_name)
      end
    end

    private

    def register(event_name, handler, priority:, &block)
      callable = handler || block
      return unless callable

      @mutex.synchronize do
        @registry[event_name] << {
          handler: callable,
          priority: priority,
          registered_at: Time.respond_to?(:current) ? Time.current : Time.now
        }
      end
    end

    def extensions_for(store, names)
      Array(names).flat_map { |name| store[name.to_sym] }
    end

    def execute_hook(handler, *)
      if handler.respond_to?(:call)
        handler.call(*)
      elsif handler.respond_to?(:to_proc)
        handler.to_proc.call(*)
      end
    end

    def handle_hook_error(error, event_name, hook)
      raise HookError, "Hook failed for #{event_name}: #{error.message}" if @raise_on_error

      log_hook_error(error, event_name, hook)
    end

    def log_hook_error(error, event_name, _hook)
      return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

      Rails.logger.error "[RecordingStudioCommentable::Hooks] Error in #{event_name} hook: #{error.message}"
      Rails.logger.error error.backtrace.first(5).join("\n") if error.backtrace
    end

    class << self
      def run(event_name, *)
        RecordingStudioCommentable.configuration.hooks.run(event_name, *)
      end

      def run_around(event_name, context, &)
        RecordingStudioCommentable.configuration.hooks.run_around(event_name, context, &)
      end

      def trigger(event_name, *)
        run(event_name, *)
      end
    end
  end
end
