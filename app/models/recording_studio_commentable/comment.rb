# frozen_string_literal: true

require "recording_studio_commentable/display_attribute_resolver"

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

    recording_studio_recordable(
      label: "Comment",
      plural_label: "Comments",
      root: false,
      allowed_parent_types: ["RecordingStudioCommentable::Comment"]
    ) if respond_to?(:recording_studio_recordable)

    # Polymorphic author — typically a User or service account
    belongs_to :author, polymorphic: true, optional: true

    validates :body, presence: true

    # Friendly display of the author's identity
    def author_display_name
      return "Anonymous" unless author

      configured_name = RecordingStudioCommentable::DisplayAttributeResolver.string_value_for(
        author,
        mappings: RecordingStudioCommentable::DisplayAttributeResolver.mapping_for_configuration(:author_display_attributes),
        fallback_attributes: %i[display_name name]
      )

      configured_name || author.to_s
    end

    def author_avatar_url
      return unless author

      RecordingStudioCommentable::DisplayAttributeResolver.string_value_for(
        author,
        mappings: RecordingStudioCommentable::DisplayAttributeResolver.mapping_for_configuration(:author_avatar_attributes)
      )
    end
  end
end
