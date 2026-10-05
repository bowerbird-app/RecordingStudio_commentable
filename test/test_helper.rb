# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "rails"
require "recording_studio_commentable"

# Minitest 6 dropped Object#stub. Keep a tiny replacement for generator/engine tests.
module CommentableMinitestStub
  def stub(name, val = nil)
    name = name.to_sym
    original = begin
      method(name)
    rescue NameError
      nil
    end

    define_singleton_method(name) do |*args, **kwargs, &block|
      if val.respond_to?(:call)
        val.call(*args, **kwargs, &block)
      else
        val
      end
    end

    yield
  ensure
    if original
      define_singleton_method(name, original)
    elsif singleton_class.method_defined?(name, false) ||
          singleton_class.private_method_defined?(name, false)
      singleton_class.remove_method(name)
    end
  end
end

Object.include(CommentableMinitestStub) unless Object.method_defined?(:stub)
