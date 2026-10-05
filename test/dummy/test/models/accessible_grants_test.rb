# frozen_string_literal: true

require_relative "../test_helper"

class AccessibleGrantsTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_seed
    @admin = User.find_by!(email: "admin@admin.com")
    @quinn = User.find_by!(email: "quinn@admin.com")
    @viewer = User.find_by!(email: "view@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
  end

  test "seeded grants store string roles and go through Accessible services" do
    grants = RecordingStudioAccessible.access_recordings_for(@public_recording).map(&:recordable)

    assert(grants.any?)
    assert(grants.all? { |access| access.role.is_a?(String) })
    assert_equal "admin", RecordingStudioAccessible.role_for(actor: @admin, recording: @public_recording).to_s
    assert_equal "edit", RecordingStudioAccessible.role_for(actor: @quinn, recording: @public_recording).to_s
    assert_equal "view", RecordingStudioAccessible.role_for(actor: @viewer, recording: @public_recording).to_s
  end

  test "grant_access upserts a string role without writing Access rows directly" do
    extra = User.create!(
      email: "extra-#{SecureRandom.hex(4)}@admin.com",
      password: "Password",
      password_confirmation: "Password",
      name: "Extra Editor"
    )

    result = RecordingStudioAccessible.grant_access(
      recording: @public_recording,
      actor: extra,
      role: :edit,
      manager_actor: @admin
    )

    assert result.success?, result.error.to_s
    access = result.value.recordable
    assert_equal "edit", access.role
    assert RecordingStudioAccessible.authorized?(actor: extra, recording: @public_recording, role: :edit)
  end
end
