# frozen_string_literal: true

require_relative "hooks"

module RecordingStudioCommentable
  class Configuration
    attr_accessor :timeout, :rich_text_comments
    attr_reader :hooks

    def initialize
      @timeout = 5
      @rich_text_comments = false
      @hooks = Hooks.new
    end

    def to_h
      {
        timeout: timeout,
        rich_text_comments: rich_text_comments,
        hooks_registered: hooks.registered_events
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
