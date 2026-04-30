# frozen_string_literal: true

module RecordingStudioCommentable
  module Services
    # Base service class following the Command pattern.
    #
    # @example
    #   result = MyService.call(param: "value")
    #   result.success? # => true
    #   result.value    # => whatever perform returned
    #
    class BaseService
      class Result
        attr_reader :value, :error, :errors

        def initialize(success:, value: nil, error: nil, errors: [])
          @success = success
          @value = value
          @error = error
          @errors = errors
        end

        def success?
          @success
        end

        def failure?
          !@success
        end

        def on_success
          yield(value) if success? && block_given?
          self
        end

        def on_failure
          yield(error, errors) if failure? && block_given?
          self
        end

        def value!
          raise error if failure?

          value
        end
      end

      class << self
        def call(*, **, &)
          new(*, **).call(&)
        end
      end

      def call
        run_before_hooks
        result = run_with_around_hooks
        run_after_hooks(result)
        yield(result) if block_given?
        result
      end

      private

      def perform
        raise NotImplementedError, "#{self.class}#perform must be implemented"
      end

      def success(value = nil)
        Result.new(success: true, value: value)
      end

      def failure(error, errors: [])
        error_message = error.is_a?(Exception) ? error.message : error
        Result.new(success: false, error: error_message, errors: errors)
      end

      def run_before_hooks
        return unless hooks_enabled?

        RecordingStudioCommentable::Hooks.run(:before_service, self.class, service_args)
      end

      def run_after_hooks(result)
        return unless hooks_enabled?

        RecordingStudioCommentable::Hooks.run(:after_service, self.class, result)
      end

      def run_with_around_hooks
        if hooks_enabled? && RecordingStudioCommentable.configuration.hooks.registered?(:around_service)
          RecordingStudioCommentable::Hooks.run_around(:around_service, self) { perform }
        else
          perform
        end
      end

      def hooks_enabled?
        defined?(RecordingStudioCommentable) &&
          RecordingStudioCommentable.respond_to?(:configuration) &&
          RecordingStudioCommentable.configuration.respond_to?(:hooks)
      end

      def service_args
        {}
      end
    end
  end
end
