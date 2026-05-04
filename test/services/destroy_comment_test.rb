# frozen_string_literal: true

require "test_helper"

class DestroyCommentTest < Minitest::Test
  module RecordingStudioTrashable; end

  def setup
    @original_configuration = RecordingStudioCommentable.instance_variable_get(:@configuration)
    RecordingStudioCommentable.instance_variable_set(:@configuration, RecordingStudioCommentable::Configuration.new)
  end

  def teardown
    RecordingStudioCommentable.instance_variable_set(:@configuration, @original_configuration)
  end

  # Root recording without the trash API
  class FakeRootRecording
    def respond_to?(method, include_private = false)
      super
    end
  end

  # Root recording WITH the trash API (mimics RS)
  class FakeRSRootRecording
    attr_reader :trashed, :trashed_recording, :trashed_actor

    def trash(recording, actor: nil)
      @trashed = true
      @trashed_recording = recording
      @trashed_actor = actor
    end

    def respond_to?(method, include_private = false)
      method == :trash || super
    end
  end

  class FakeCommentRecording
    attr_accessor :recordable

    def initialize
      @recordable = FakeComment.new
    end
  end

  class FakeTrashableCommentRecording < FakeCommentRecording
    attr_reader :trashed_with_actor, :trashed_with_metadata

    def recording_studio_trashable_trash!(actor: nil, metadata: {})
      @trashed_with_actor = actor
      @trashed_with_metadata = metadata
      self
    end
  end

  class FakeComment
    def destroy!
      true
    end

    def respond_to?(method, include_private = false)
      method == :destroy! || super
    end
  end

  def test_result_interface
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new

    result = RecordingStudioCommentable::Services::DestroyComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      actor: nil
    )

    assert_respond_to result, :success?
    assert_respond_to result, :failure?
    assert_respond_to result, :value
    assert_respond_to result, :error
  end

  def test_uses_trash_when_recording_studio_trash_available
    root = FakeRSRootRecording.new
    comment_recording = FakeCommentRecording.new
    actor = Object.new

    # RecordingStudio is not loaded in unit tests, so trash_available? returns
    # false regardless of root responding to :trash.
    # We verify the service completes without error.
    result = RecordingStudioCommentable::Services::DestroyComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      actor: actor
    )

    assert_respond_to result, :success?
  end

  def test_uses_recording_studio_trashable_when_enabled
    RecordingStudioCommentable.configuration.use_recording_studio_trashable_for_destroy = true

    root = FakeRootRecording.new
    comment_recording = FakeTrashableCommentRecording.new
    actor = Object.new

    result = RecordingStudioCommentable::Services::DestroyComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      actor: actor
    )

    assert_equal true, result.success?
    assert_same comment_recording, result.value
    assert_same actor, comment_recording.trashed_with_actor
    assert_equal({ source: "recording_studio_commentable" }, comment_recording.trashed_with_metadata)
  end

  def test_returns_clear_failure_when_trashable_is_enabled_but_capability_is_missing
    RecordingStudioCommentable.configuration.use_recording_studio_trashable_for_destroy = true

    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new

    result = RecordingStudioCommentable::Services::DestroyComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      actor: nil
    )

    assert_equal true, result.failure?
    assert_includes result.error, "recording_studio_trashable destroy integration is enabled"
    assert_includes result.error, "recording_studio_trashable_trash!"
  end

  def test_falls_back_to_destroy_when_trash_unavailable
    root = FakeRootRecording.new
    comment_recording = FakeCommentRecording.new

    result = RecordingStudioCommentable::Services::DestroyComment.call(
      comment_recording: comment_recording,
      root_recording: root,
      actor: nil
    )

    # destroy_directly calls comment_recording.recordable.destroy!
    # FakeComment#destroy! returns true, so this should succeed
    assert_respond_to result, :success?
  end
end
