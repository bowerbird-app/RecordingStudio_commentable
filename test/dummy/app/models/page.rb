# frozen_string_literal: true

# Page is a commentable recordable — including Commentable opts it in to the
# comment feed provided by RecordingStudioCommentable.
class Page < ApplicationRecord
  include RecordingStudioCommentable::Commentable

  validates :title, presence: true
end
