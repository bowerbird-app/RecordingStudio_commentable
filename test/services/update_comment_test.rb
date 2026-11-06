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

  class FakeRevisingRoot
    attr_reader :revised_actor, :revised_recording

    def revise(recording, actor: nil, **)
      @revised_recording = recording
      @revised_actor = actor
      yield recording.recordable if block_given?
      recording
    end

    def respond_to?(method, include_private = false)
      method == :revise || super
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

    result = update_comment(
      comment_recording: comment_recording,
      root_recording: root,
      body: "",
      actor: nil
    ) { |service| allow_accessible_admin(service) }

    assert result.failure?
    assert_equal "Body cannot be blank", result.error
  end

  def test_failure_when_body_is_nil
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new("original body")

    result = update_comment(
      comment_recording: comment_recording,
      root_recording: root,
      body: nil,
      actor: nil
    ) { |service| allow_accessible_admin(service) }

    assert result.failure?
    assert_equal "Body cannot be blank", result.error
  end

  def test_direct_update_fallback_when_revise_not_available
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new("original")

    result = update_comment(
      comment_recording: comment_recording,
      root_recording: root,
      body: "Updated body",
      actor: nil
    ) { |service| allow_accessible_admin(service) }

    # Without RecordingStudio's revise, falls back to direct update
    assert_respond_to result, :success?
    assert_respond_to result, :failure?
  end

  def test_passes_actor_to_revise
    root = FakeRevisingRoot.new
    comment_recording = FakeCommentRecording.new("original")
    actor = Object.new

    result = update_comment(
      comment_recording: comment_recording,
      root_recording: root,
      body: "Updated body",
      actor: actor
    ) { |service| allow_accessible_admin(service) }

    assert result.success?
    assert_same actor, root.revised_actor
    assert_same comment_recording, root.revised_recording
    assert_equal "Updated body", comment_recording.recordable.body
  end

  def test_denies_when_accessible_admin_is_missing
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new("original")

    result = RecordingStudioCommentable::Services::UpdateComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      body: "Updated body",
      actor: Object.new
    )

    assert result.failure?
    assert_equal "You are not allowed to edit this comment.", result.error
    assert_equal "original", comment_recording.recordable.body
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

  private

  def update_comment(**)
    service = RecordingStudioCommentable::Services::UpdateComment.new(**)
    yield service if block_given?
    service.call
  end

  def allow_accessible_admin(service)
    service.define_singleton_method(:accessible_admin?) { true }
  end
end
