# frozen_string_literal: true

# Page is a commentable recordable — `.to` opts it in to the comment feed
# provided by RecordingStudioCommentable.
class Page < ApplicationRecord
  recording_studio_recordable(
    label: "Page",
    plural_label: "Pages",
    root: true
  )

  include RecordingStudio::Capabilities::Commentable.to

  RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)
  RecordingStudio.enable_capability(:api_access_point, on: self) if defined?(RecordingStudioApi)

  validates :title, presence: true
end
