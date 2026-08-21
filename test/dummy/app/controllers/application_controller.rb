require "recording_studio_commentable/recordable_display_helper"
require "recording_studio_commentable/comment_body_helper"
require "recording_studio_commentable/comment_routes_helper"

class ApplicationController < ActionController::Base
  include RecordingStudioCommentable::CommentBodyHelper
  include RecordingStudioCommentable::CommentRoutesHelper
  include RecordingStudioCommentable::RecordableDisplayHelper
  include RecordingStudio::UsesDefaultLayout if defined?(RecordingStudio::UsesDefaultLayout)

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  layout :application_layout

  before_action :authenticate_user!
  before_action :set_current_actor

  helper_method :current_recording_studio_actor,
                :commentable_recording_comments_path,
                :commentable_all_recording_comments_path,
                :commentable_new_recording_comment_path,
                :commentable_reply_comment_path,
                :recordable_display_title,
                :truncate_comment_body

  private

  def application_layout
    devise_controller? ? "devise" : "recording_studio/default_layout"
  end

  def set_current_actor
    Current.actor = current_user
  end

  def current_recording_studio_actor
    Current.actor || current_user
  end
end
