# frozen_string_literal: true

require "test_helper"

class CapabilityTest < Minitest::Test
  # Minimal stand-in for a recordable host model
  class PlainModel
    include ActiveSupport::Concern
  end

  class CommentableModel
    include ActiveSupport::Concern
    include RecordingStudioCommentable::Commentable
  end

  class AnotherCommentableModel
    include RecordingStudioCommentable::Commentable
  end

  def test_commentable_module_exists
    assert defined?(RecordingStudioCommentable::Commentable), "Commentable module should be defined"
  end

  def test_included_class_has_commentable_instance_predicate
    instance = AnotherCommentableModel.new
    assert_respond_to instance, :commentable?
    assert instance.commentable?
  end

  def test_included_class_has_commentable_class_predicate
    assert_respond_to AnotherCommentableModel, :commentable?
    assert AnotherCommentableModel.commentable?
  end

  def test_non_commentable_class_does_not_respond_to_commentable
    plain = PlainModel.new
    refute plain.respond_to?(:commentable?), "Plain model should not have commentable?"
  end

  def test_include_detection_via_include_check
    assert CommentableModel.include?(RecordingStudioCommentable::Commentable)
  end

  def test_non_commentable_does_not_include_module
    refute PlainModel.respond_to?(:include?) && PlainModel.include?(RecordingStudioCommentable::Commentable)
  rescue TypeError
    # Expected: PlainModel doesn't mix in the Commentable concern
    pass
  end
end
