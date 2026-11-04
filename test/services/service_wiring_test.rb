# frozen_string_literal: true

require "test_helper"

# Smoke test to ensure service infrastructure wiring is correct after rename.
# Full CreateComment/UpdateComment/DestroyComment service tests live in their
# own files (services/create_comment_test.rb, etc.).
module RecordingStudioCommentable
  module Services
    class ServiceWiringTest < Minitest::Test
      class EchoService < BaseService
        def initialize(message:)
          @message = message
        end

        private

        def perform
          return failure("Message cannot be blank") if @message.nil? || @message.strip.empty?

          success(@message)
        end
      end

      def test_success_with_valid_message
        result = EchoService.call(message: "hello")

        assert result.success?
        assert_equal "hello", result.value
      end

      def test_failure_with_blank_message
        result = EchoService.call(message: "")

        assert result.failure?
        assert_equal "Message cannot be blank", result.error
      end

      def test_failure_with_nil_message
        result = EchoService.call(message: nil)

        assert result.failure?
      end

      def test_block_syntax
        received = nil
        EchoService.call(message: "Ruby") do |result|
          result.on_success { |value| received = value }
        end

        assert_equal "Ruby", received
      end
    end
  end
end
