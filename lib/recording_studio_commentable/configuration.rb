# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCommentable
  class Configuration
    attr_accessor :timeout
    attr_reader :hooks

    def initialize
      @timeout = 5
      @hooks = Hooks.new
    end

    def to_h
      {
        timeout: timeout,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
