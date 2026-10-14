# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
require "rails"
require "yaml"
require "recording_studio_commentable"

# Gem suite does not boot the dummy Rails app, so engine initializers never
# run. Register commentable English into RecordingStudio::Translation and seed
# the I18n backend so RecordingStudio.t / service errors resolve without
# hand-copied default: strings.
COMMENTABLE_EN_YML = File.expand_path("../config/locales/en.yml", __dir__)
if defined?(RecordingStudio::Translation) &&
   RecordingStudio::Translation.respond_to?(:register_shipped_english)
  RecordingStudio::Translation.register_shipped_english(COMMENTABLE_EN_YML)
  RecordingStudio::Translation.shipped_english
end
begin
  I18n.backend.store_translations(:en, YAML.safe_load_file(COMMENTABLE_EN_YML, aliases: true).fetch("en"))
rescue StandardError
  # Ignore when I18n is not ready yet; individual tests seed as needed.
end

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
      value.transform_values { |nested| deep_plain_i18n_copy(nested) }
    when Array
      value.map { |nested| deep_plain_i18n_copy(nested) }
    else
      value
    end
  end
end

Minitest::Test.include(CommentableI18nBackendHelpers)
