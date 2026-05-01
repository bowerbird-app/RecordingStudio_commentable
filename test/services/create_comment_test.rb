# frozen_string_literal: true

require "test_helper"
require "active_model"

class CreateCommentTest < Minitest::Test
  # Minimal recording double that mimics the RS record API
  class FakeRecording
    attr_reader :children, :last_record_class, :last_record_kwargs

    def initialize
      @children = []
    end

    def record(klass, **kwargs)
      @last_record_class = klass
      @last_record_kwargs = kwargs
      obj = klass.new
      yield obj if block_given?
      @children << obj
      obj
    end

    def respond_to?(method, include_private = false)
      method == :record || super
    end
  end

  # Minimal comment double using ActiveModel validations
  class FakeComment
    include ActiveModel::Validations

    attr_accessor :body, :author

    validates :body, presence: true

    def initialize
      @persisted = false
    end

    def save!
      raise ActiveModel::ValidationError, self unless valid?

      @persisted = true
    end

    def persisted?
      @persisted
    end
  end

  def setup
    # Patch Comment class used by service to FakeComment for unit testing
    @original_comment_class = RecordingStudioCommentable::Services::CreateComment.instance_method(:build_comment)
  end

  def test_failure_when_body_is_blank
    # Stub Comment.new to return a FakeComment so we don't need a DB
    fake_recording = FakeRecording.new

    # Call service with blank body — should fail fast without touching DB
    result = RecordingStudioCommentable::Services::CreateComment.call(
      parent_recording: fake_recording,
      body: "",
      author: nil
    )

    assert result.failure?
    assert_equal "Body cannot be blank", result.error
  end

  def test_failure_when_body_is_nil
    fake_recording = FakeRecording.new

    result = RecordingStudioCommentable::Services::CreateComment.call(
      parent_recording: fake_recording,
      body: nil,
      author: nil
    )

    assert result.failure?
    assert_equal "Body cannot be blank", result.error
  end

  def test_uses_recording_studio_when_available
    fake_recording = FakeRecording.new
    fake_author = Object.new

    service = RecordingStudioCommentable::Services::CreateComment.new(
      parent_recording: fake_recording,
      body: "Test comment",
      author: fake_author
    )
    service.define_singleton_method(:recording_studio_available?) { true }
    service.define_singleton_method(:build_comment) do
      FakeComment.new.tap do |comment|
        comment.body = "Test comment"
        comment.author = fake_author
      end
    end

    result = service.call

    assert result.success?
    assert_equal FakeComment, fake_recording.last_record_class
    assert_equal({ parent_recording: fake_recording }, fake_recording.last_record_kwargs)
    assert_equal 1, fake_recording.children.size
  end

  def test_result_responds_to_success_and_failure
    fake_recording = FakeRecording.new

    result = RecordingStudioCommentable::Services::CreateComment.call(
      parent_recording: fake_recording,
      body: "",
      author: nil
    )

    assert_respond_to result, :success?
    assert_respond_to result, :failure?
    assert_respond_to result, :error
    assert_respond_to result, :value
  end
end
