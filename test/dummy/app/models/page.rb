# frozen_string_literal: true

# Page is a commentable recordable — including Commentable opts it in to the
# comment feed provided by RecordingStudioCommentable.
class Page < ApplicationRecord
  recording_studio_recordable(
    label: "Page",
    plural_label: "Pages",
    root: true
  )

  include RecordingStudioCommentable::Commentable

  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)

  validates :title, presence: true
end
