# frozen_string_literal: true

require_relative "../test_helper"

class AccessiblePinTest < ActiveSupport::TestCase
  test "pins Accessible 0.54.0 with trashable query deps and audience tables" do
    assert_equal "0.54.0", RecordingStudioAccessible::VERSION

    gemfile = File.read(Rails.root.join("Gemfile"))
    assert_includes gemfile, 'gem "recording_studio_accessible"'
    assert_includes gemfile, 'tag: "v0.54.0"'
    assert_includes gemfile, 'gem "recording_studio_trashable"'
    assert_includes gemfile, 'tag: "v1.2.0"'
    assert_includes gemfile, 'gem "recording_studio_metrics"'
    assert_includes gemfile, 'tag: "v0.9.1"'

    assert ActiveRecord::Base.connection.table_exists?(:recording_studio_access_constraints)
    assert ActiveRecord::Base.connection.table_exists?(:recording_studio_access_rules)
    assert RecordingStudio::Recording.respond_to?(:kept)
    refute RecordingStudio::Recording.respond_to?(:recording_studio_trashable_kept_sql)
    assert ActiveRecord::Base.connection.column_exists?(:recording_studio_events, :root_recording_id)

    home = File.read(Rails.root.join("app/controllers/home_controller.rb"))
    assert_includes home, ".kept"
    refute_includes home, "recording_studio_trashable_kept_sql"
  end
end
