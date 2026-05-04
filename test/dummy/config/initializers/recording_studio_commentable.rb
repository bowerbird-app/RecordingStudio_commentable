# frozen_string_literal: true

RecordingStudioCommentable.configure do |config|
  config.layout = ""
  config.rich_text_comments = true
  config.recordable_display_attributes = {
    "Page" => :title,
    "Folder" => :name
  }
  config.author_display_attributes = {
    "User" => :display_name
  }
  config.author_avatar_attributes = {
    "User" => :avatar_url
  }
end