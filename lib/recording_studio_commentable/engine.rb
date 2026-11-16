# frozen_string_literal: true

module RecordingStudioCommentable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioCommentable
    config.paths.add "app/components", eager_load: true

    initializer "recording_studio_commentable.register_recording_studio_capability" do
      next unless defined?(RecordingStudio)

      RecordingStudio.register_recordable_type("RecordingStudioCommentable::Comment")
      RecordingStudio.register_capability(
        :commentable,
        source: "recording_studio_commentable",
        child_recordables: ["RecordingStudioCommentable::Comment"]
      )
    end

    initializer "recording_studio_commentable.register_recording_studio_api",
                before: "recording_studio_api.after_initialize" do
      RecordingStudioCommentable::Api.register!
      config.to_prepare { RecordingStudioCommentable::Api.register! }
    end

    initializer "recording_studio_commentable.register_shipped_english",
                before: "recording_studio.load_shipped_english" do
      next unless defined?(RecordingStudio::Translation)
      next unless RecordingStudio::Translation.respond_to?(:register_shipped_english)

      RecordingStudio::Translation.register_shipped_english(
        root.join("config/locales/en.yml")
      )
    end

    initializer "recording_studio_commentable.load_config" do |app|
      if app.respond_to?(:config_for)
        begin
          yaml = app.config_for(:recording_studio_commentable)
        rescue StandardError
          yaml = nil
        end
        RecordingStudioCommentable.configuration.merge!(yaml) if yaml.respond_to?(:each)
      end

      if app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_commentable)
        xcfg = app.config.x.recording_studio_commentable
        if xcfg.respond_to?(:to_h)
          RecordingStudioCommentable.configuration.merge!(xcfg.to_h)
        else
          begin
            hash = {}
            xcfg.each_pair { |k, v| hash[k] = v } if xcfg.respond_to?(:each_pair)
            RecordingStudioCommentable.configuration.merge!(hash) if hash&.any?
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
