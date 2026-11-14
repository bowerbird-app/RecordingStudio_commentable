# frozen_string_literal: true

require "test_helper"

class ApiTest < Minitest::Test
  def test_register_is_a_noop_when_recording_studio_api_is_unavailable
    refute RecordingStudioCommentable::Api.recording_studio_api_available? unless api_available?

    RecordingStudioCommentable::Api.stub(:recording_studio_api_available?, false) do
      assert_nil RecordingStudioCommentable::Api.register!
    end
  end

  def test_registers_comment_recordable_type_and_write_handlers
    skip "recording_studio_api is not available" unless api_available?

    RecordingStudioCommentable::Api.register!
    RecordingStudioCommentable::Api.register!

    registration = RecordingStudioApi.recordable_registration_for(
      RecordingStudioCommentable::Api::RECORDABLE_TYPE
    )

    refute_nil registration
    assert_equal %i[create destroy index show update], registration.operations.sort
    assert_equal %w[body], registration.writable_attributes
    assert_equal false, registration.auto_capability_actions
    assert registration.fields.key?("comment_count")
    assert registration.relationships.key?("replies")
    assert_equal RecordingStudioCommentable::Api::Create,
                 RecordingStudioApi.resource_handler(RecordingStudioCommentable::Api::RECORDABLE_TYPE, :create)
    assert_equal RecordingStudioCommentable::Api::Update,
                 RecordingStudioApi.resource_handler(RecordingStudioCommentable::Api::RECORDABLE_TYPE, :update)
    assert_equal RecordingStudioCommentable::Api::Destroy,
                 RecordingStudioApi.resource_handler(RecordingStudioCommentable::Api::RECORDABLE_TYPE, :destroy)
  end

  def test_does_not_fake_recording_studio_api
    Dir[File.expand_path("../lib/**/*.rb", __dir__)].each do |path|
      source = File.read(path)
      refute_includes source, "const_set", "#{path} must not fake constants"
      refute_includes source, "remove_const", "#{path} must not fake constants"
    end
  end

  def test_create_update_and_destroy_wrap_existing_services
    create_source = File.read(File.expand_path("../lib/recording_studio_commentable/api/create.rb", __dir__))
    update_source = File.read(File.expand_path("../lib/recording_studio_commentable/api/update.rb", __dir__))
    destroy_source = File.read(File.expand_path("../lib/recording_studio_commentable/api/destroy.rb", __dir__))

    assert_includes create_source, "RecordingStudioCommentable::Services::CreateComment.call"
    assert_includes create_source, "authorize_access!(parent_recording, role: :edit)"
    assert_includes create_source, "assert_commentable!(parent_recording)"
    assert_includes create_source, "RecordingStudio.capability_enabled?(:commentable, for: type)"
    assert_includes update_source, "RecordingStudioCommentable::Services::UpdateComment.call"
    assert_includes update_source, "resource_attributes[:body]"
    assert_includes update_source, "access_grant.authorize!(recording: parent_recording, role: :admin)"
    refute_includes update_source, "request_payload"
    refute_includes update_source, "params[:body]"
    assert_includes destroy_source, "RecordingStudioCommentable::Services::DestroyComment.call"
    assert_includes destroy_source, "access_grant.authorize!(recording: parent_recording, role: :admin,"
    assert_includes destroy_source, "include_trashed: true)"
    assert_includes destroy_source, 'deleted_via: "trashed"'
  end

  private

  def api_available?
    RecordingStudioCommentable::Api.recording_studio_api_available?
  end
end
