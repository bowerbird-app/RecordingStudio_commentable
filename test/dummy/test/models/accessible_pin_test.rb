# frozen_string_literal: true

require_relative "../test_helper"

class AccessiblePinTest < ActiveSupport::TestCase
  test "pins Accessible 0.22.2 with trashable query deps and audience tables" do
    assert_equal "0.22.2", RecordingStudioAccessible::VERSION

    gemfile = File.read(Rails.root.join("Gemfile"))
    assert_includes gemfile, 'gem "recording_studio_accessible"'
    assert_includes gemfile, 'tag: "v0.22.2"'
    assert_includes gemfile, 'gem "recording_studio_trashable"'
    assert_includes gemfile, 'tag: "v0.12.0"'
    assert_includes gemfile, 'gem "recording_studio_metrics"'
    assert_includes gemfile, 'tag: "v0.7.0"'

    assert ActiveRecord::Base.connection.table_exists?(:recording_studio_access_constraints)
    assert ActiveRecord::Base.connection.table_exists?(:recording_studio_access_rules)
    assert RecordingStudio::Recording.respond_to?(:recording_studio_trashable_kept_sql)
  end
end
