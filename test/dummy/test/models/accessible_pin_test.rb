# frozen_string_literal: true

require_relative "../test_helper"

class AccessiblePinTest < ActiveSupport::TestCase
  test "pins Accessible 0.15.0 and has audience constraint and rule tables" do
    assert_equal "0.15.0", RecordingStudioAccessible::VERSION

    gemfile = File.read(Rails.root.join("Gemfile"))
    assert_includes gemfile, 'gem "recording_studio_accessible"'
    assert_includes gemfile, 'tag: "v0.15.0"'

    assert ActiveRecord::Base.connection.table_exists?(:recording_studio_access_constraints)
    assert ActiveRecord::Base.connection.table_exists?(:recording_studio_access_rules)
  end
end
