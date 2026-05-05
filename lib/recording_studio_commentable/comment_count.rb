# frozen_string_literal: true

module RecordingStudioCommentable
  module CommentCount
    COMMENT_RECORDABLE_TYPE = "RecordingStudioCommentable::Comment"

    module_function

    def for_recording(recording)
      return 0 unless recording&.respond_to?(:id)
      return 0 unless defined?(RecordingStudio::Recording)

      visited_ids = Set.new([recording.id])
      frontier_ids = [recording.id]
      total = 0

      while frontier_ids.any?
        child_ids = RecordingStudio::Recording
                    .where(parent_recording_id: frontier_ids)
                    .where(recordable_type: COMMENT_RECORDABLE_TYPE)
                    .where(trashed_at: nil)
                    .pluck(:id)

        unseen_child_ids = child_ids.reject { |id| visited_ids.include?(id) }
        total += unseen_child_ids.size
        visited_ids.merge(unseen_child_ids)
        frontier_ids = unseen_child_ids
      end

      total
    end
  end
end
