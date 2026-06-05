# frozen_string_literal: true

module RecordingStudioCommentable
  module CommentsButton
    class Component < ViewComponent::Base
      def initialize(recording:, count: nil, style: :primary, size: :lg, text: nil, **button_options)
        super()
        @recording = recording
        @count = count
        @style = style
        @size = size
        @text = text
        @button_options = button_options
      end

      def call
        render FlatPack::Button::Component.new(**button_arguments)
      end

      private

      attr_reader :recording, :button_options, :style, :size, :text

      def button_arguments
        args = button_options.merge(
          text: button_text,
          style: style,
          size: size,
          disabled: disabled?
        )
        args[:url] = destination_path unless disabled?
        args
      end

      def button_text
        text.presence || "#{comments_count} #{'Comment'.pluralize(comments_count)}"
      end

      def destination_path
        helpers.commentable_all_recording_comments_path(recording, return_to: current_request_path)
      end

      def current_request_path
        request = helpers.request
        return unless request

        request.fullpath
      end

      def comments_count
        @comments_count ||= @count.nil? ? descendant_comment_count : @count.to_i
      end

      def descendant_comment_count
        RecordingStudioCommentable::CommentCount.for_recording(recording)
      end

      def disabled?
        @disabled ||= !view_authorized?
      end

      def view_authorized?
        return true unless defined?(RecordingStudioAccessible)

        actor = current_actor
        return false unless actor

        RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)
      end

      def current_actor
        if helpers.respond_to?(:current_recording_studio_actor)
          helpers.current_recording_studio_actor
        elsif defined?(Current) && Current.respond_to?(:actor)
          Current.actor
        end
      end
    end
  end
end
