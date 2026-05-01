# frozen_string_literal: true

module RecordingStudioCommentable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioCommentable

    class << self
      def apply_model_extensions(target)
        apply_extensions(target,
                         RecordingStudioCommentable.configuration.hooks.model_extensions_for(extension_keys_for(target)))
      end

      def apply_controller_extensions(target)
        apply_extensions(target,
                         RecordingStudioCommentable.configuration.hooks.controller_extensions_for(extension_keys_for(target)))
      end

      private

      def apply_extensions(target, extensions)
        return unless target

        applied = target.instance_variable_get(:@recording_studio_commentable_applied_extensions) || identity_hash

        extensions.flatten.compact.each do |extension|
          next if applied[extension]

          target.class_eval(&extension)
          applied[extension] = true
        end

        target.instance_variable_set(:@recording_studio_commentable_applied_extensions, applied)
      end

      def extension_keys_for(target)
        names = [target.name, target.name&.demodulize].compact.uniq
        names.map(&:to_sym)
      end

      def identity_hash
        {}.compare_by_identity
      end
    end

    initializer "recording_studio_commentable.before_initialize",
                before: "recording_studio_commentable.load_config" do |_app|
      RecordingStudioCommentable::Hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_commentable.load_config" do |app|
      if app.respond_to?(:config_for)
        begin
          yaml = app.config_for(:recording_studio_commentable)
          RecordingStudioCommentable.configuration.merge!(yaml) if yaml.respond_to?(:each)
        rescue StandardError
          # ignore; host app can provide initializer overrides
        end
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_commentable)
        begin
          xcfg = app.config.x.recording_studio_commentable
          if xcfg.respond_to?(:to_h)
            RecordingStudioCommentable.configuration.merge!(xcfg.to_h)
          elsif xcfg.respond_to?(:each_pair)
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v }
            RecordingStudioCommentable.configuration.merge!(hash) if hash.any?
          end
        rescue StandardError
          # ignore
        end
      end

      RecordingStudioCommentable::Hooks.run(:on_configuration, RecordingStudioCommentable.configuration)
    end

    initializer "recording_studio_commentable.after_initialize",
                after: "recording_studio_commentable.load_config" do |_app|
      RecordingStudioCommentable::Hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_commentable.apply_model_extensions" do
      config.to_prepare do
        next unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.each do |model|
          next if model.abstract_class?

          RecordingStudioCommentable::Engine.apply_model_extensions(model)
        end
      end
    end

    initializer "recording_studio_commentable.apply_controller_extensions" do
      config.to_prepare do
        next unless defined?(ActionController::Base)

        ActionController::Base.descendants.each do |controller|
          RecordingStudioCommentable::Engine.apply_controller_extensions(controller)
        end
      end
    end
  end
end
