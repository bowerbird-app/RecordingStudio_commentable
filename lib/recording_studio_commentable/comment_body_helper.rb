# frozen_string_literal: true

require "action_view/helpers/text_helper"
require "rails-html-sanitizer"

module RecordingStudioCommentable
  module CommentBodyHelper
    include ActionView::Helpers::TextHelper

    def truncate_comment_body(comment_or_body, length: 280, omission: "...")
      body = extract_comment_body(comment_or_body)
      normalized_body = Rails::Html::FullSanitizer.new.sanitize(body.to_s).squish
      return "" if normalized_body.blank?

      truncate(normalized_body, length: length, omission: omission, separator: " ")
    end

    private

    def extract_comment_body(comment_or_body)
      return comment_or_body.body if comment_or_body.respond_to?(:body)

      comment_or_body
    end
  end
end
