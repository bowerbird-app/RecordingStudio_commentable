# frozen_string_literal: true

module RecordingStudioCommentable
  # Commentable capability concern for recordable models.
  #
  # Include this in any recordable model to opt it in to comments.
  # The CommentsController checks for this module before allowing
  # comment operations on a recording.
  #
  # @example
  #   class Page < ApplicationRecord
  #     include RecordingStudioCommentable::Commentable
  #   end
  #
  #   page.commentable? # => true
  #
  module Commentable
    extend ActiveSupport::Concern

    included do
      # Marker — presence of this module signals that the recordable type
      # supports comments. No extra columns needed on the host model.
    end

    # Returns true so controllers can check `recordable.commentable?`
    def commentable?
      true
    end

    class_methods do
      # Returns true so class-level checks work too.
      def commentable?
        true
      end
    end
  end
end
