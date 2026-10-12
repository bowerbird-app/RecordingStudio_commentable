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
    singleton = singleton_class
    had_singleton = singleton.method_defined?(name, false) || singleton.private_method_defined?(name, false)
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
    if singleton.method_defined?(name, false) || singleton.private_method_defined?(name, false)
      singleton.remove_method(name)
    end
    define_singleton_method(name, original) if had_singleton && original
  end
end

Object.include(CommentableMinitestStub) unless Object.method_defined?(:stub)

module CommentableI18nBackendHelpers
  def i18n_backend_translations_snapshot
    backend = I18n.backend
    backend.send(:init_translations) unless backend.initialized?
    translations =
      if backend.respond_to?(:translations)
        backend.translations
      else
        backend.instance_variable_get(:@translations)
      end
    return unless translations

    deep_plain_i18n_copy(translations)
  end

  def restore_i18n_backend_translations(snapshot)
    backend = I18n.backend
    backend.instance_variable_set(:@translations, snapshot)
    backend.instance_variable_set(:@initialized, true) if backend.instance_variable_defined?(:@initialized)
  end

  def deep_plain_i18n_copy(value)
    case value
    when Hash
      value.each_with_object({}) { |(key, nested), copy| copy[key] = deep_plain_i18n_copy(nested) }
    when Array
      value.map { |nested| deep_plain_i18n_copy(nested) }
    else
      value
    end
  end
end

Minitest::Test.include(CommentableI18nBackendHelpers)
