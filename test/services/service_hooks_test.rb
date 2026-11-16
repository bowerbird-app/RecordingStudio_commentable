# frozen_string_literal: true

require "test_helper"
require "active_support/core_ext/time/zones"

Time.zone ||= "UTC"

module RecordingStudioCommentable
  module Services
    class ServiceHooksTest < Minitest::Test
      def test_commentable_does_not_own_a_hooks_registry
        refute RecordingStudioCommentable.const_defined?(:Hooks, false)
        refute RecordingStudioCommentable::Services.const_defined?(:BaseService, false)
        refute_respond_to RecordingStudioCommentable.configuration, :hooks
        refute RecordingStudioCommentable.configuration.to_h.key?(:hooks_registered)
      end

      def test_comment_services_run_core_hooks_filtered_by_service_class
        seen = Hash.new { |events, name| events[name] = [] }

        with_core_hooks do |hooks|
          hooks.before_service do |service_class, args|
            next unless comment_service?(service_class)

            seen[:before] << [service_class, args]
          end
          hooks.after_service do |service_class, result|
            next unless service_class == CreateComment

            seen[:after] << result
          end
          hooks.around_service do |service, block|
            seen[:around] << service.class if service.instance_of?(CreateComment)
            block.call
          end

          create_result = CreateComment.call(parent_recording: nil, body: "", author: nil)
          UpdateComment.call(comment_recording: Object.new, root_recording: nil, body: "text", actor: nil)
          DestroyComment.call(comment_recording: Object.new, root_recording: nil, actor: nil)

          assert_instance_of RecordingStudio::Services::BaseService::Result, create_result
          assert create_result.failure?
          assert_equal "Body cannot be blank", create_result.error
        end

        assert_equal [
          [CreateComment, { body: "", author: nil }],
          [UpdateComment, { body: "text", actor: nil }],
          [DestroyComment, { actor: nil }]
        ], seen[:before]
        assert_equal [CreateComment], seen[:around]
        assert_equal 1, seen[:after].length
        assert_instance_of RecordingStudio::Services::BaseService::Result, seen[:after].first
        assert seen[:after].first.failure?
      end

      private

      def comment_service?(service_class)
        [CreateComment, UpdateComment, DestroyComment].include?(service_class)
      end

      def with_core_hooks
        hooks = RecordingStudio.configuration.hooks
        registry = hooks.instance_variable_get(:@registry)
        snapshot = registry.transform_values(&:dup)

        yield hooks
      ensure
        restore_hook_registry(registry, snapshot)
      end

      def restore_hook_registry(registry, snapshot)
        return unless registry && snapshot

        (registry.keys - snapshot.keys).each { |name| registry.delete(name) }
        snapshot.each { |name, handlers| registry[name] = handlers }
      end
    end
  end
end
