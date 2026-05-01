# frozen_string_literal: true

require "test_helper"

class CommentsPagesFlowTest < Minitest::Test
  def test_comments_routes_include_all_collection_page
    routes_source = read_workspace_file("config/routes.rb")

    assert_includes routes_source, "get :all, path: \"all\""
  end

  def test_engine_home_lists_comments_with_back_navigation
    controller_source = read_workspace_file("app/controllers/recording_studio_commentable/home_controller.rb")
    view_source = read_workspace_file("app/views/recording_studio_commentable/home/index.html.erb")
    page_partial_source = read_workspace_file("app/views/recording_studio_commentable/home/_comments_page.html.erb")
    comment_partial_source = read_workspace_file("app/views/recording_studio_commentable/comments/_comment.html.erb")
    infinite_scroll_controller_source = read_workspace_file("test/dummy/app/javascript/controllers/infinite_scroll_controller.js")
    application_js_source = read_workspace_file("test/dummy/app/javascript/application.js")
    importmap_source = read_workspace_file("test/dummy/config/importmap.rb")

    assert_includes controller_source, "@external_back_path = scenarios_target_path"
    assert_includes controller_source, "all_entries = visible_comment_entries"
    assert_includes controller_source, "@comment_entries = paginated_entries(all_entries)"
    assert_includes controller_source, "@next_page = next_page_for(all_entries)"
    assert_includes controller_source, "parent_recording = root_recording_for(comment_recording.parent_recording)"
    assert_includes controller_source,
                    'render partial: "comments_page", locals: comments_page_locals, layout: false if turbo_frame_request?'
    assert_includes controller_source,
            'return main_app.scenarios_path(anchor: "comment-scenarios") if main_app.respond_to?(:scenarios_path)'
    assert_includes view_source, '{ text: "Back", href: @external_back_path }'
    assert_includes view_source, 'title: "Commentable"'
    assert_includes view_source, 'subtitle: "All comments"'
    assert_includes view_source, 'render "comments_page"'
    assert_includes page_partial_source, 'turbo_frame_tag "comments_page_#{page}"'
    assert_includes page_partial_source, 'class: (page.to_i > 1 ? "mt-3" : nil)'
    assert_includes page_partial_source, 'return_to: @external_back_path'
    assert_includes page_partial_source, 'controller: "infinite-scroll"'
    assert_includes page_partial_source, '"infinite-scroll-url-value": url_for(page: next_page)'
    assert_includes page_partial_source, "accessible: entry[:accessible]"
    assert_includes comment_partial_source, "parent_title.present?"
    assert_includes comment_partial_source, 'text: "Show"'
    assert_includes comment_partial_source, "local_assigns.fetch(:accessible, true)"
    assert_includes comment_partial_source, 'url: recording_comments_path(parent_recording, return_to: return_to)'
    assert_includes comment_partial_source, 'data: { turbo_frame: "_top" }'
    assert_includes comment_partial_source, "Comment hidden"
    assert_includes comment_partial_source, "pointer-events-none"
    assert_includes infinite_scroll_controller_source, "new IntersectionObserver"
    assert_includes infinite_scroll_controller_source, "this.element.src = this.urlValue"
    assert_includes application_js_source, 'import "@hotwired/turbo-rails"'
    assert_includes importmap_source, 'pin "@hotwired/turbo-rails", to: "turbo.min.js"'
  end

  def test_comments_controller_uses_plain_layout_and_internal_flow
    application_controller_source = read_workspace_file("app/controllers/recording_studio_commentable/application_controller.rb")
    controller_source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")
    layout_source = read_workspace_file("app/views/layouts/recording_studio_commentable/application.html.erb")

    assert_includes application_controller_source, 'layout "recording_studio_commentable/application"'
    assert_includes controller_source, "before_action :authorize_view!, only: %i[index all]"
    assert_includes controller_source, "def all"
    assert_includes controller_source, "redirect_to comments_collection_path,"
    assert_includes controller_source,
                    "@external_back_path = commentable_home_referer_path || return_to_path || main_app.root_path"
    assert_includes controller_source, "normalized_home_paths = [root_path, root_path.chomp(\"/\")].uniq"
    assert_includes controller_source, 'referer_uri.query.present? ? "#{referer_uri.path}?#{referer_uri.query}" : referer_uri.path'
    refute_includes controller_source, "layout :comments_layout"
    assert_includes layout_source, '<%= stylesheet_link_tag "flat_pack/application", "data-turbo-track": "reload" %>'
    refute_includes layout_source, "FlatPack::SidebarLayout::Component"
  end

  def test_summary_page_template_shows_text_block_and_dynamic_bottom_button
    view_source = read_workspace_file("app/views/recording_studio_commentable/comments/index.html.erb")

    assert_includes view_source, '{ text: "Back", href: @external_back_path }'
    assert_includes view_source, "@comments_count.positive? ? @comments_collection_path : @new_comment_path"
    assert_includes view_source, '@comments_count.positive? ? "#{@comments_count} Comments" : "Add comment"'
  end

  def test_all_comments_page_template_shows_back_button_and_add_comment_button
    view_source = read_workspace_file("app/views/recording_studio_commentable/comments/all.html.erb")

    assert_includes view_source, '{ text: "Back", href: @summary_path }'
    assert_includes view_source, 'title: "Comments"'
    assert_includes view_source, 'text: "Add comment"'
    assert_includes view_source, '<%= render "comment", comment_recording: comment_recording %>'
  end

  def test_new_comment_page_and_comment_actions_preserve_return_to_flow
    new_view_source = read_workspace_file("app/views/recording_studio_commentable/comments/new.html.erb")
    comment_partial_source = read_workspace_file("app/views/recording_studio_commentable/comments/_comment.html.erb")

    assert_includes new_view_source,
                    '{ text: "Back", href: (@comments_count.to_i.positive? ? @comments_collection_path : @summary_path) }'
    assert_includes new_view_source, 'title: "Add comment"'
    assert_includes new_view_source, "recording_comments_path(@parent_recording, return_to: params[:return_to])"
    assert_includes comment_partial_source, "local_assigns[:parent_recording] || @parent_recording"
    assert_includes comment_partial_source, "local_assigns[:parent_title]"
    assert_includes comment_partial_source, "local_assigns[:show_page_action]"
    assert_includes comment_partial_source,
            "url: edit_recording_comment_path(parent_recording, comment_recording, return_to: return_to)"
    assert_includes comment_partial_source,
                    "recording_comment_path(parent_recording, comment_recording, return_to: return_to)"
  end

  private

  def read_workspace_file(path)
    File.read(File.expand_path("../#{path}", __dir__))
  end
end
