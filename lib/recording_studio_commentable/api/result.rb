# frozen_string_literal: true

module RecordingStudioCommentable
  module Api
    module Result
      module_function

      def raise_for!(result)
        return if result.success?

        raise RecordingStudioApi::InvalidActionInputError, result.error.to_s
      end
    end
  end
end
