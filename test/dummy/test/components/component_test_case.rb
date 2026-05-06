# frozen_string_literal: true

require_relative "../test_helper"
require "view_component/test_case"
require "stringio"
require "time"

class ComponentTestCase < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    load_seed_data

    @admin = User.find_by!(email: "admin@admin.com")
    @viewer = User.find_by!(email: "view@admin.com")
    @public_page = Page.find_by!(title: "Quinn and Admin User can comment")
    @admin_page = Page.find_by!(title: "Admin User owns this document")
    @public_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @public_page)
    @admin_recording = RecordingStudio::Recording.unscoped.find_by!(recordable: @admin_page)
    normalize_seed_comment_timestamps!

    Current.actor = @admin
  end

  teardown do
    Current.reset if Current.respond_to?(:reset)
  end

  private

  def load_seed_data
    original_stdout = $stdout
    $stdout = StringIO.new
    Rails.application.load_seed
  ensure
    $stdout = original_stdout
  end

  def render_component(component, request_url: "/components")
    with_controller_class(ApplicationController) do
      with_request_url(request_url) do
        render_inline(component)
      end
    end
  end

  def render_component_in_turbo_frame(component, request_url:, turbo_frame:)
    with_controller_class(ApplicationController) do
      vc_test_request.headers["Turbo-Frame"] = turbo_frame
      with_request_url(request_url) do
        render_inline(component)
      end
    ensure
      vc_test_request.headers["Turbo-Frame"] = nil
    end
  end

  def normalize_seed_comment_timestamps!
    {
      "Welcome to the shared thread. Use this page to verify the default comments feed with seeded content." => "2026-01-01 10:00:00 UTC",
      "Reply sample: Quinn can respond here, which makes the feed show a threaded conversation immediately." => "2026-01-01 10:01:00 UTC",
      "A second top-level comment gives the paginated feed examples enough items to demonstrate the different loading modes." => "2026-01-01 10:02:00 UTC"
    }.each do |body, timestamp|
      comment = RecordingStudioCommentable::Comment.find_by!(body: body)
      recording = RecordingStudio::Recording.unscoped.find_by!(recordable: comment)
      instant = Time.parse(timestamp)
      RecordingStudioCommentable::Comment.where(id: comment.id).update_all(created_at: instant, updated_at: instant)
      recording.update_columns(created_at: instant, updated_at: instant)
    end
  end
end