# frozen_string_literal: true

module RecordingStudioCommentable
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
