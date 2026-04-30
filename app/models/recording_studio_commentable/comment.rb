# frozen_string_literal: true

module RecordingStudioCommentable
  # Stores the body text and authorship of a single comment.
  #
  # A Comment is intended to be used as a RecordingStudio recordable — each
  # instance is wrapped in a Recording that tracks history. Comments are
  # created/updated/deleted through the Services layer, which handles the
  # RecordingStudio record/revise/trash pattern.
  #
  # Table: recording_studio_comments
  #   - id (uuid, pk)
  #   - body (text, not null)
  #   - author_type / author_id (polymorphic)
  #   - created_at / updated_at
  #
  class Comment < ApplicationRecord
    self.table_name = "recording_studio_comments"

    # Polymorphic author — typically a User or service account
    belongs_to :author, polymorphic: true, optional: true

    validates :body, presence: true

    # Friendly display of the author's identity
    def author_display_name
      return "Anonymous" unless author

      author.respond_to?(:display_name) ? author.display_name : author.to_s
    end
  end
end
