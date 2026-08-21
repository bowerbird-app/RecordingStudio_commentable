# frozen_string_literal: true

require_relative "../test_helper"

class CommentableCapabilityTest < ActiveSupport::TestCase
  test "pages opt in with Commentable.to and folders stay without commentable" do
    assert_respond_to RecordingStudio::Capabilities::Commentable, :to
    assert RecordingStudio.capability_enabled?(:commentable, for: "Page")
    refute RecordingStudio.capability_enabled?(:commentable, for: "Folder")
    refute RecordingStudio.capability_enabled?(:commentable, for: "Workspace")
    assert_equal({}, RecordingStudio.capability_options(:commentable, for: "Page"))
  end

  test "installing the gem does not enable commentable on undeclared types" do
    refute RecordingStudio.capability_enabled?(:commentable, for: "User")
  end
end
