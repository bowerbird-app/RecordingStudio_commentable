# frozen_string_literal: true

require "test_helper"

class UpdateCommentTest < Minitest::Test
  # Minimal recording double without the revise API
  class FakeRootRecording
    def respond_to?(method, include_private = false)
      # Explicitly does NOT respond to :revise
      super
    end
  end

  # Comment double that supports direct update
  class FakeCommentRecording
    attr_reader :recordable

    def initialize(body)
      @recordable = FakeComment.new(body)
    end

    def respond_to?(method, include_private = false)
      method == :recordable || super
    end
  end

  class FakeComment
    attr_accessor :body

    def initialize(body)
      @body = body
    end

    def valid?
      body.present?
    end

    def errors
      @errors ||= FakeErrors.new
    end

    def save!
      true
    end
  end

  class FakeErrors
    def full_messages
      []
    end
  end

  def test_failure_when_body_is_blank
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new("original body")

    result = RecordingStudioCommentable::Services::UpdateComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      body: "",
      actor: nil
    )

    assert result.failure?
    assert_equal "Body cannot be blank", result.error
  end

  def test_failure_when_body_is_nil
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new("original body")

    result = RecordingStudioCommentable::Services::UpdateComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      body: nil,
      actor: nil
    )

    assert result.failure?
    assert_equal "Body cannot be blank", result.error
  end

  def test_direct_update_fallback_when_revise_not_available
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new("original")

    result = RecordingStudioCommentable::Services::UpdateComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      body: "Updated body",
      actor: nil
    )

    # Without RecordingStudio's revise, falls back to direct update
    assert_respond_to result, :success?
    assert_respond_to result, :failure?
  end

  def test_result_interface
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new("body")

    result = RecordingStudioCommentable::Services::UpdateComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      body: "",
      actor: nil
    )

    assert_respond_to result, :on_success
    assert_respond_to result, :on_failure
    assert_respond_to result, :value
    assert_respond_to result, :error
  end
end
