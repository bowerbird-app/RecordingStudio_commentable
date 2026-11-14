# frozen_string_literal: true

require_relative "../test_helper"

class ApiRecordableRegistrationTest < ActiveSupport::TestCase
  test "eager-loaded API AdminApi stays on the host recordable type list" do
    skip "recording_studio_api is not available" unless defined?(RecordingStudioApi)

    require "recording_studio_api/admin_api" unless defined?(RecordingStudioApi::AdminApi)

    assert_includes RecordingStudio.configuration.recordable_types, "RecordingStudioApi::AdminApi"
    assert_empty RecordingStudioApi.configuration.admin_root_recordable_type_names
    assert RecordingStudio.validate_recordable_declarations!
  end
end
