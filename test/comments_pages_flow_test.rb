# frozen_string_literal: true

require "test_helper"

class CommentsPagesFlowTest < Minitest::Test
  def test_comments_routes_include_all_collection_page
    routes_source = read_workspace_file("config/routes.rb")
    dummy_routes_source = read_workspace_file("test/dummy/config/routes.rb")

    assert_includes routes_source, "resources :comments, only: [] do"
    assert_includes routes_source, "get :reply"
    assert_includes routes_source, "post :reply, action: :create_reply"
    refute_includes routes_source, "resources :recordings, only: [] do"
    assert_includes dummy_routes_source, "scope module: :recording_studio_commentable do"
    assert_includes dummy_routes_source, "resources :comments, only: %i[index new create edit update destroy] do"
    assert_includes dummy_routes_source, "get :all, path: \"all\""
    assert_includes dummy_routes_source, 'get "/recordings", to: "home#recordings", as: :recordings_browser'
    assert_includes dummy_routes_source, 'get "/recordings/:id", to: "home#recording", as: :recording_browser'
    assert_includes dummy_routes_source, 'get "/gem-routes", to: "home#gem_routes", as: :gem_routes'
    assert_includes dummy_routes_source, 'get "/helpers", to: "home#helpers", as: :helpers'
    refute_includes dummy_routes_source, 'get "up" => "rails/health#show", as: :rails_health_check'
  end

  def test_dummy_gem_routes_page_lists_gem_route_catalog_and_sidebar_link
    controller_source = read_workspace_file("test/dummy/app/controllers/home_controller.rb")
    view_source = read_workspace_file("test/dummy/app/views/home/gem_routes.html.erb")
    sidebar_source = read_workspace_file("test/dummy/app/views/layouts/flat_pack/_sidebar.html.erb")

    assert_includes controller_source, "before_action :load_gem_route_catalog, only: :gem_routes"
    assert_includes controller_source, "def gem_routes"
    assert_includes controller_source, "RecordingStudioCommentable::Engine.routes"
    assert_includes controller_source, 'path_prefix: "/commentable"'
    assert_includes controller_source, 'controller_prefix: "recording_studio_commentable/"'
    assert_includes controller_source, "route_set.routes.filter_map do |route|"
    assert_includes controller_source, "route.path.spec.to_s.delete_suffix(\"(.:format)\")"
    assert_includes view_source, 'title: "Gem routes"'
    assert_includes view_source,
                    'subtitle: "A dummy-app reference for the RecordingStudioCommentable routes exposed by the mounted engine and the host app."'
    assert_includes view_source, "@gem_route_groups.each do |group|"
    assert_includes view_source, "title: group[:title]"
    assert_includes view_source, "group[:routes].each do |route|"
    assert_includes view_source, "FlatPack::Badge::Component.new(text: route[:verb], style: :info, size: :sm)"
    assert_includes view_source, ">Path<"
    assert_includes view_source, ">Helper<"
    assert_includes view_source, ">Controller<"
    assert_includes view_source, ">Action<"
    assert_includes sidebar_source, 'label: "Gem routes"'
    assert_includes sidebar_source, 'href: "/gem-routes"'
    assert_includes sidebar_source, "icon: :git_branch"
  end

  def test_dummy_recordings_pages_expose_recording_structure_and_sidebar_link
    controller_source = read_workspace_file("test/dummy/app/controllers/home_controller.rb")
    index_view_source = read_workspace_file("test/dummy/app/views/home/recordings.html.erb")
    detail_view_source = read_workspace_file("test/dummy/app/views/home/recording.html.erb")
    sidebar_source = read_workspace_file("test/dummy/app/views/layouts/flat_pack/_sidebar.html.erb")

    assert_includes controller_source, "before_action :load_recording_catalog, only: :recordings"
    assert_includes controller_source, "before_action :load_recording_detail, only: :recording"
    assert_includes controller_source, "def recordings"
    assert_includes controller_source, "def recording"
    assert_includes controller_source, '.where(recordable_type: ["Folder", "Page"])'
    assert_includes controller_source, ".where(parent_recording_id: nil)"
    assert_includes controller_source, "@recording_entries = @recordings.map do |recording|"
    assert_includes controller_source, "@recording_snapshot = recording_snapshot(@recording)"
    assert_includes controller_source, "@recording_children = structure_child_recordings(@recording)"
    assert_includes controller_source, "@recording_events = structure_events(@recording)"
    assert_includes controller_source, "def structure_child_recordings(recording)"
    assert_includes controller_source, "def structure_events(recording)"
    assert_includes controller_source, ".where(parent_recording: recording)"
    assert_includes controller_source, ".pluck(:id)"
    assert_includes controller_source, "def recording_snapshot(recording)"
    assert_includes index_view_source, 'title: "Recordings"'
    assert_includes index_view_source, "@recording_entries.each do |entry|"
    assert_includes index_view_source, 'text: "Inspect structure"'
    assert_includes index_view_source, "url: recording_browser_path(recording)"
    assert_includes detail_view_source, "href: recordings_browser_path"
    assert_includes detail_view_source, 'title: "Recording"'
    assert_includes detail_view_source, 'title: "Child recordings"'
    assert_includes detail_view_source, 'title: "Events"'
    assert_includes detail_view_source, 'title: "Recordable"'
    assert_includes detail_view_source, "title: @recording_snapshot[:title]"
    assert_includes detail_view_source, "@recording_children.each do |child|"
    assert_includes detail_view_source, "@recording_events.each do |entry|"
    assert_includes detail_view_source, "border-l border-(--surface-border-color)"
    assert_includes detail_view_source, 'text: "Open child"'
    assert_includes sidebar_source, 'label: "Recordings"'
    assert_includes sidebar_source, 'href: "/recordings"'
    assert_includes sidebar_source, "icon: :file"
  end

  def test_dummy_helpers_page_lists_available_helpers_public_services_and_host_api
    controller_source = read_workspace_file("test/dummy/app/controllers/home_controller.rb")
    view_source = read_workspace_file("test/dummy/app/views/home/helpers.html.erb")
    sidebar_source = read_workspace_file("test/dummy/app/views/layouts/flat_pack/_sidebar.html.erb")

    assert_includes controller_source, "before_action :load_helper_catalog, only: :helpers"
    assert_includes controller_source, "def helpers"
    assert_includes controller_source, 'title: "recordable_display_title"'
    assert_includes controller_source, 'title: "truncate_comment_body"'
    assert_includes controller_source, 'title: "current_recording_studio_actor"'
    assert_includes controller_source, 'title: "commentable_reply_comment_path"'
    assert_includes controller_source, 'title: "CreateComment.call"'
    assert_includes controller_source, 'title: "UpdateComment.call"'
    assert_includes controller_source, 'title: "DestroyComment.call"'
    assert_includes controller_source, 'title: "BaseService::Result"'
    assert_includes controller_source, 'title: "RecordingStudioCommentable.configure"'
    assert_includes controller_source, 'title: "RecordingStudioCommentable.configuration"'
    assert_includes controller_source, 'title: "Commentable concern"'
    assert_includes controller_source, 'title: "Comment author methods"'
    assert_includes controller_source, 'title: "Hooks API"'
    assert_includes controller_source, 'title: "Mounted routes"'
    assert_includes controller_source,
                    "RecordableDisplayHelper is included in both the dummy app controller and the engine controller."
    assert_includes controller_source,
                    "CommentRoutesHelper exposes the mounted reply route helper used by the gem-owned reply composer flow."
    assert_includes view_source, 'title: "View helpers"'
    assert_includes view_source, 'title: "Exposed helper methods"'
    assert_includes view_source, 'title: "Public services"'
    assert_includes view_source, 'title: "Host app API"'
    assert_includes view_source,
                    'subtitle: "A dummy-app reference for the helper methods exposed by RecordingStudioCommentable and the host controller layer."'
    assert_includes view_source, "@helper_catalog.each do |helper_entry|"
    assert_includes view_source, "@service_catalog.each do |service_entry|"
    assert_includes view_source, "@host_api_catalog.each do |api_entry|"
    assert_includes view_source, "helper_entry[:examples].each do |example|"
    assert_includes view_source, 'title: "Shared notes"'
    assert_includes view_source, 'title: "Where they show up"'
    assert_includes sidebar_source, 'label: "Helpers"'
    assert_includes sidebar_source, 'href: "/helpers"'
    assert_includes sidebar_source, "icon: :settings"
    refute_includes sidebar_source, 'label: "Health"'
    refute_includes sidebar_source, 'href: "/up"'
  end

  def test_dummy_components_page_lists_component_catalog_and_sidebar_link
    controller_source = read_workspace_file("test/dummy/app/controllers/home_controller.rb")
    view_source = read_workspace_file("test/dummy/app/views/home/components.html.erb")
    sidebar_source = read_workspace_file("test/dummy/app/views/layouts/flat_pack/_sidebar.html.erb")
    routes_source = read_workspace_file("test/dummy/config/routes.rb")

    assert_includes controller_source, "before_action :load_component_catalog, only: :components"
    assert_includes controller_source, "def components"
    assert_includes controller_source, "def load_component_catalog"
    assert_includes controller_source, 'title: "RecordingStudioCommentable::CommentsButton::Component"'
    assert_includes controller_source,
                    'signature: "RecordingStudioCommentable::CommentsButton::Component.new(recording:, count: nil, style: :primary, size: :lg, text: nil, **button_options)"'
    assert_includes controller_source, 'name: "recording:"'
    assert_includes controller_source, 'name: "count:"'
    assert_includes controller_source, 'name: "style:"'
    assert_includes controller_source, 'name: "size:"'
    assert_includes controller_source, 'name: "text:"'
    assert_includes controller_source, 'name: "**button_options"'
    assert_includes controller_source,
                    "render RecordingStudioCommentable::CommentsButton::Component.new(recording: recording)"
    assert_includes controller_source,
                    'input: "render RecordingStudioCommentable::CommentsButton::Component.new(recording: recording, count: 12, style: :secondary, size: :sm, class: \"justify-center\")"'
    assert_includes controller_source,
                    'input: "render RecordingStudioCommentable::CommentsButton::Component.new(recording: recording, text: \"Open discussion\", class: \"w-full justify-center\", data: { turbo: false })"'
    assert_includes controller_source, "all_recording_comments_path(example_recording, return_to: return_to_path)"
    assert_includes controller_source, 'title: "RecordingStudioCommentable::CommentsFeed::Component"'
    assert_includes controller_source,
                    'signature: "RecordingStudioCommentable::CommentsFeed::Component.new(recording:, mode: :all, page_size: 20, include_composer: false, return_to: nil, comment: nil, can_create_comment: nil, reply_action: nil)"'
    assert_includes controller_source, 'name: "mode:"'
    assert_includes controller_source, 'name: "page_size:"'
    assert_includes controller_source, 'name: "include_composer:"'
    assert_includes controller_source, 'name: "return_to:"'
    assert_includes controller_source, 'name: "comment:"'
    assert_includes controller_source, 'name: "can_create_comment:"'
    assert_includes controller_source, 'name: "reply_action:"'
    assert_includes controller_source,
                    "render RecordingStudioCommentable::CommentsFeed::Component.new(recording: recording)"
    assert_includes controller_source,
                    "render RecordingStudioCommentable::CommentsFeed::Component.new(recording: recording, mode: :infinite, page_size: 2)"
    assert_includes controller_source,
                    "render RecordingStudioCommentable::CommentsFeed::Component.new(recording: recording, mode: :load_more, page_size: 2, include_composer: true, return_to: recording_comments_path(recording))"
    assert_includes controller_source,
                    'label: "Thread with replies"'
    assert_includes controller_source,
                    'input: "render RecordingStudioCommentable::CommentsFeed::Component.new(recording: recording_with_replies, mode: :all)"'
    assert_includes controller_source,
                    'label: "Custom reply action"'
    assert_includes controller_source, "reply_action: lambda do |default_options:, **|"
    assert_includes controller_source, 'text: "Reply inline"'
    assert_includes controller_source,
                    "Nested replies are rendered one level deep inside the shared comment partial, and nested reply rows do not expose a Reply action."
    assert_includes controller_source,
                    "Reply defaults to the mounted gem reply composer route using the shared inline FlatPack comments-link style."
    assert_includes view_source, 'title: "Components"'
    assert_includes view_source, "@component_catalog.each do |component_entry|"
    assert_includes view_source, "title: component_entry[:title]"
    assert_includes view_source, "Parameters"
    assert_includes view_source, "component_entry[:params].each do |param|"
    assert_includes view_source, "component_entry[:examples].each do |example|"
    assert_includes view_source, "render example[:preview].call"
    refute_includes view_source, 'title: "Notes"'
    refute_includes view_source, 'title: "Quick links"'
    assert_includes sidebar_source, 'label: "Components"'
    assert_includes sidebar_source, 'href: "/components"'
    assert_includes sidebar_source, "icon: :blocks"
    assert_includes routes_source, 'get "/components", to: "home#components", as: :components'
  end

  def test_engine_home_lists_comments_with_back_navigation
    controller_source = read_workspace_file("app/controllers/recording_studio_commentable/home_controller.rb")
    view_source = read_workspace_file("app/views/recording_studio_commentable/home/index.html.erb")
    page_partial_source = read_workspace_file("app/views/recording_studio_commentable/home/_comments_page.html.erb")
    comment_partial_source = read_workspace_file("app/views/recording_studio_commentable/comments/_comment.html.erb")
    infinite_scroll_controller_source = read_workspace_file("test/dummy/app/javascript/controllers/infinite_scroll_controller.js")
    application_js_source = read_workspace_file("test/dummy/app/javascript/application.js")
    importmap_source = read_workspace_file("test/dummy/config/importmap.rb")

    assert_includes controller_source, "all_entries = visible_comment_entries"
    assert_includes controller_source, "@comment_entries = paginated_entries(all_entries)"
    assert_includes controller_source, "@next_page = next_page_for(all_entries)"
    assert_includes controller_source, "top_level_comments = visible_top_level_comment_recordings"
    assert_includes controller_source, "replies_by_parent = load_replies(top_level_comments)"
    assert_includes controller_source, "parent_recording = root_recording_for(comment_recording.parent_recording)"
    assert_includes controller_source, "visible_top_level_comment_recordings"
    assert_includes controller_source, "comment_recording?(comment_recording.parent_recording)"
    assert_includes controller_source, "replies: replies_by_parent.fetch(comment_recording.id, [])"
    assert_includes controller_source, "next if workspace_recording?(parent_recording)"
    assert_includes controller_source, "group_by(&:parent_recording_id)"
    assert_includes controller_source, 'recording.recordable_type == "Workspace"'
    assert_includes controller_source, 'recording.recordable_type == "RecordingStudioCommentable::Comment"'
    assert_includes controller_source,
                    'render partial: "comments_page", locals: comments_page_locals, layout: false if turbo_frame_request?'
    assert_includes controller_source, "@external_back_path = main_app.root_path"
    assert_includes view_source, '{ text: "Back", href: @external_back_path }'
    assert_includes view_source, 'title: "Recording Studio Commentable"'
    assert_includes view_source, 'subtitle: "All comments"'
    assert_includes view_source, 'render "comments_page"'
    assert_includes page_partial_source, 'turbo_frame_tag "comments_page_#{page}"'
    assert_includes page_partial_source, 'class: (page.to_i > 1 ? "mt-3" : nil)'
    assert_includes page_partial_source, "return_to: @external_back_path"
    assert_includes page_partial_source, 'controller: "infinite-scroll"'
    assert_includes page_partial_source, '"infinite-scroll-url-value": url_for(page: next_page)'
    assert_includes page_partial_source, "accessible: entry[:accessible]"
    assert_includes page_partial_source, "replies: entry[:replies]"
    assert_includes comment_partial_source, "local_assigns.fetch(:accessible, true)"
    assert_includes comment_partial_source, "configuration.rich_text_comments_enabled?"
    assert_includes comment_partial_source, "FlatPack::RichTextSanitizer.sanitize(comment.body.to_s).html_safe"
    assert_includes comment_partial_source, "Comment hidden"
    refute_includes comment_partial_source, 'text: "Show"'
    refute_includes comment_partial_source, 'text: "Edit"'
    refute_includes comment_partial_source, 'text: "Delete"'
    assert_includes infinite_scroll_controller_source, "new IntersectionObserver"
    assert_includes infinite_scroll_controller_source, "this.element.src = this.urlValue"
    assert_includes application_js_source, 'import "@hotwired/turbo-rails"'
    assert_includes importmap_source, 'pin "@hotwired/turbo-rails", to: "turbo.min.js"'
    assert_includes importmap_source,
                    'pin_all_from FlatPack::Engine.root.join("app/javascript/flat_pack/tiptap"), under: "flat_pack/tiptap", to: "flat_pack/tiptap"'
    assert_includes importmap_source, 'pin "flat_pack/heroicons", to: "flat_pack/heroicons.js"'
    assert_includes importmap_source, 'TIPTAP_VERSION = "2.11.5"'
    assert_includes importmap_source, 'pin "@tiptap/core", to: "https://esm.sh/@tiptap/core@#{TIPTAP_VERSION}"'
    assert_includes importmap_source, 'pin "@tiptap/starter-kit", to: "https://esm.sh/@tiptap/starter-kit@#{TIPTAP_VERSION}"'
    assert_includes importmap_source, 'pin "lowlight", to: "https://esm.sh/lowlight"'
  end

  def test_comments_controller_uses_plain_layout_and_internal_flow
    application_controller_source = read_workspace_file("app/controllers/recording_studio_commentable/application_controller.rb")
    controller_source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")
    layout_source = read_workspace_file("app/views/layouts/recording_studio_commentable/application.html.erb")

    assert_includes application_controller_source, "include RecordingStudioCommentable::CommentBodyHelper"
    assert_includes application_controller_source, "layout :commentable_layout"
    assert_includes application_controller_source, "helper_method :truncate_comment_body"
    assert_includes application_controller_source,
                    'RecordingStudioCommentable.configuration.layout.presence || "recording_studio_commentable/application"'
    assert_includes controller_source, "before_action :authorize_view!, only: %i[index all reply]"
    assert_includes controller_source, "def all"
    assert_includes controller_source, "@show_comments = summary_show_comments_request?"
    assert_includes controller_source, "@comment = Comment.new"
    assert_includes controller_source, "redirect_to comments_collection_path,"
    assert_includes controller_source, "redirect_to post_create_redirect_path,"
    assert_includes controller_source, "redirect_to commentable_home_referer_path || comments_collection_path,"
    assert_includes controller_source, "if inline_composer_request? && summary_show_comments_request?"
    assert_includes controller_source, "render :index, status: :unprocessable_entity"
    assert_includes controller_source, "if inline_composer_request?"
    assert_includes controller_source, "render :all, status: :unprocessable_entity"
    assert_includes controller_source,
                    "@external_back_path = commentable_home_referer_path || external_return_to_path || main_app.root_path"
    assert_includes controller_source,
                    "@back_button_onclick = external_return_to_path.present? ? nil : 'if (window.history.length > 1) { event.preventDefault(); window.history.back(); }'"
    assert_includes controller_source, "@can_create_comment = authorized?(:edit)"
    assert_includes controller_source, "ActiveModel::Type::Boolean.new.cast(params[:inline_composer])"
    assert_includes controller_source, "ActiveModel::Type::Boolean.new.cast(params[:show_comments])"
    assert_includes controller_source, "return_to_options.merge(show_comments ? { show_comments: true } : {})"
    assert_includes controller_source, "main_app.recording_comments_path("
    assert_includes controller_source,
                    "main_app.all_recording_comments_path(@parent_recording, return_to_options.merge(feed_query_options))"
    assert_includes controller_source, "main_app.new_recording_comment_path(@parent_recording, return_to_options)"
    assert_includes controller_source, "def external_return_to_path"
    assert_includes controller_source, "while (next_path = nested_comment_return_to_path(path))"
    assert_includes controller_source, "params = Rack::Utils.parse_nested_query(uri.query.to_s)"
    assert_includes controller_source, "def comment_navigation_path?(path)"
    assert_includes controller_source, "def normalize_relative_path(path)"
    assert_includes controller_source, "uri.query.present?"
    assert_includes controller_source, "normalized_home_paths = [root_path, root_path.chomp(\"/\")].uniq"
    assert_includes controller_source,
                    "referer_uri.query.present? ? \"\#{referer_uri.path}?\#{referer_uri.query}\" : referer_uri.path"
    refute_includes controller_source, "layout :comments_layout"
    assert_includes layout_source, '<%= stylesheet_link_tag "flat_pack/application", "data-turbo-track": "reload" %>'
    assert_includes layout_source, '<%= stylesheet_link_tag "flat_pack/rich_text", "data-turbo-track": "reload" %>'
    assert_includes layout_source, '<%= stylesheet_link_tag "flat_pack/content_editor", "data-turbo-track": "reload" %>'
    assert_includes layout_source, '<html class="h-full overflow-hidden overscroll-none">'
    assert_includes layout_source,
                    '<body class="m-0 h-full overflow-hidden overscroll-none bg-[var(--surface-page-background-color)] text-[var(--surface-content-color)]">'
    assert_includes layout_source, '<main class="h-full overflow-auto">'
    refute_includes layout_source, "FlatPack::SidebarLayout::Component"
  end

  def test_summary_page_template_shows_text_block_and_dynamic_bottom_button
    view_source = read_workspace_file("app/views/recording_studio_commentable/comments/index.html.erb")
    widget_source = read_workspace_file("app/components/recording_studio_commentable/comments_button/component.rb")
    count_source = read_workspace_file("lib/recording_studio_commentable/comment_count.rb")
    controller_source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")

    assert_includes view_source, 'text: "Back"'
    assert_includes view_source, "href: @external_back_path"
    assert_includes view_source, "onclick: @back_button_onclick"
    assert_includes view_source, "data: { turbo: false }"
    assert_includes view_source, "}.compact"
    assert_includes view_source, "unless @show_comments"
    assert_includes view_source,
                    "RecordingStudioCommentable::CommentsButton::Component.new("
    assert_includes view_source, "recording: @parent_recording"
    refute_includes view_source,
                    "RecordingStudioCommentable::CommentsButton::Component.new(\n          recording: @parent_recording,\n          count: @comments_count"
    assert_includes view_source, "if @show_comments"
    assert_includes view_source, "show_comments: true,"
    assert_includes view_source, "inline_composer: true"
    assert_includes view_source, "main_app.recording_comments_path("
    assert_includes view_source,
                    'Comments <span class="font-medium text-(--comments-thread-count-color)">(<%= @comments_count %>)</span>'
    assert_includes widget_source, "class Component < ViewComponent::Base"
    assert_includes widget_source, "'Comment'.pluralize(comments_count)"
    assert_includes widget_source,
                    "helpers.main_app.all_recording_comments_path(recording, return_to: current_request_path)"
    assert_includes widget_source, "RecordingStudioCommentable::CommentCount.for_recording(recording)"
    assert_includes widget_source,
                    "RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)"
    assert_includes count_source, 'COMMENT_RECORDABLE_TYPE = "RecordingStudioCommentable::Comment"'
    assert_includes count_source, "where(parent_recording_id: frontier_ids)"
    assert_includes count_source, "where(recordable_type: COMMENT_RECORDABLE_TYPE)"
    assert_includes controller_source, "@comments_count = comment_count"
    assert_includes controller_source, "RecordingStudioCommentable::CommentCount.for_recording(@parent_recording)"
  end

  def test_all_comments_page_template_shows_back_button_and_comment_thread
    view_source = read_workspace_file("app/views/recording_studio_commentable/comments/all.html.erb")
    component_source = read_workspace_file("app/components/recording_studio_commentable/comments_feed/component.rb")
    component_template_source = read_workspace_file("app/components/recording_studio_commentable/comments_feed/component.html.erb")
    feed_partial_source = read_workspace_file("app/views/recording_studio_commentable/comments/_feed.html.erb")
    feed_page_partial_source = read_workspace_file("app/views/recording_studio_commentable/comments/_feed_page.html.erb")
    controller_source = read_workspace_file("app/controllers/recording_studio_commentable/comments_controller.rb")

    assert_includes view_source, '{ text: "Back", href: @summary_path }'
    assert_includes view_source, "show_new_comment_button = ActiveModel::Type::Boolean.new.cast(params[:new_comment_button])"
    assert_includes view_source, 'text: "Add comment"'
    assert_includes view_source, "url: @new_comment_path"
    assert_includes view_source, "style: :secondary"
    assert_includes view_source, 'class: "justify-start"'
    assert_includes view_source, "RecordingStudioCommentable::CommentsFeed::Component.new("
    assert_includes view_source, "recording: @parent_recording"
    assert_includes view_source, "mode: params[:loading]"
    assert_includes view_source, "page_size: params[:page_size]"
    assert_includes view_source, "include_composer: !show_new_comment_button"
    assert_includes view_source, "comment: @comment"
    assert_includes view_source, "can_create_comment: @can_create_comment"
    assert_includes component_source, "LOADING_MODES = %i[all infinite load_more].freeze"
    assert_includes component_source, "DEFAULT_PAGE_SIZE = 20"
    assert_includes component_source, "mode: :all"
    assert_includes component_source, "page_size: DEFAULT_PAGE_SIZE"
    assert_includes component_source, "include_composer: false"
    assert_includes component_source, "loading_mode != :all"
    assert_includes component_source, "reply_action: nil"
    assert_includes component_source, "DEFAULT_REPLY_BUTTON_OPTIONS = {"
    assert_includes component_source, 'data: { turbo_frame: "_top" }'
    assert_includes component_source, "def reply_button_resolver"
    assert_includes component_source, "return if @reply_action.nil?"
    assert_includes component_source, "def reply_button_options_for(comment_recording, parent_recording = recording)"
    assert_includes component_source, "default_reply_button_options_for(comment_recording, parent_recording)"
    assert_includes component_source, "resolve_reply_action(comment_recording, parent_recording, default_options)"
    assert_includes component_source, "helpers.main_app.recording_comments_path(recording, args)"
    assert_includes component_source, "helpers.main_app.all_recording_comments_path("
    assert_includes component_source, "helpers.recording_studio_commentable.reply_comment_path("
    assert_includes component_source, "options[:loading] = loading_mode if paginated?"
    assert_includes component_source, "options[:page_size] = page_size if paginated?"
    assert_includes component_template_source, 'render partial: "recording_studio_commentable/comments/feed_page"'
    assert_includes component_template_source, 'render partial: "recording_studio_commentable/comments/feed"'
    assert_includes feed_partial_source, "FlatPack::Comments::Thread::Component.new("
    assert_includes feed_partial_source, 'render "recording_studio_commentable/comments/form"'
    assert_includes feed_partial_source, "force_composer: true"
    assert_includes feed_partial_source,
                    'Comments <span class="font-medium text-(--comments-thread-count-color)">(<%= feed.comments_count %>)</span>'
    assert_includes feed_page_partial_source, "turbo_frame_tag feed.page_frame_id(page)"
    assert_includes feed_page_partial_source, 'data-controller="infinite-scroll"'
    assert_includes feed_page_partial_source, 'data-infinite-scroll-url-value="<%= feed.page_path(next_page) %>"'
    assert_includes feed_page_partial_source, 'text: "Load more"'
    assert_includes feed_page_partial_source, "turbo_frame: feed.page_frame_id(next_page)"
    assert_includes controller_source, "options[:loading] = loading if %w[infinite load_more].include?(loading)"
    assert_includes controller_source, "options[:page_size] = page_size if page_size.positive?"
  end

  def test_new_comment_page_and_comment_actions_preserve_return_to_flow
    new_view_source = read_workspace_file("app/views/recording_studio_commentable/comments/new.html.erb")
    comment_partial_source = read_workspace_file("app/views/recording_studio_commentable/comments/_comment.html.erb")
    form_partial_source = read_workspace_file("app/views/recording_studio_commentable/comments/_form.html.erb")
    dummy_initializer_source = read_workspace_file("test/dummy/config/initializers/recording_studio_commentable.rb")
    scenarios_view_source = read_workspace_file("test/dummy/app/views/home/scenarios.html.erb")
    dummy_home_controller_source = read_workspace_file("test/dummy/app/controllers/home_controller.rb")
    dummy_home_index_source = read_workspace_file("test/dummy/app/views/home/index.html.erb")

    assert_includes new_view_source,
                    '{ text: "Back", href: (params[:return_to].presence || (@comments_count.to_i.positive? ? @comments_collection_path : @summary_path)) }'
    assert_includes new_view_source, "FlatPack::Comments::Thread::Component.new("
    assert_includes new_view_source, "thread.header do"
    assert_includes new_view_source, "thread.comment do"
    assert_includes new_view_source, "composer_title = @composer_title.presence"
    assert_includes new_view_source,
                    "composer_url = @composer_url || main_app.recording_comments_path(@parent_recording, return_to: params[:return_to])"
    refute_includes new_view_source,
                    "cancel_path: (@comments_count.to_i.positive? ? @comments_collection_path : @summary_path)"
    assert_includes new_view_source, "force_composer: true"
    refute_includes new_view_source, "FlatPack::Card::Component.new(style: :outlined)"
    assert_includes dummy_initializer_source, 'config.layout = ""'
    assert_includes dummy_initializer_source, "config.rich_text_comments = :"
    assert_includes dummy_initializer_source, "config.recordable_display_attributes = {"
    assert_includes dummy_initializer_source, "config.author_display_attributes = {"
    assert_includes dummy_initializer_source, "config.author_avatar_attributes = {"
    assert_includes dummy_initializer_source, '"Page" => :title'
    assert_includes dummy_initializer_source, '"User" => :display_name'
    assert_includes dummy_initializer_source, '"User" => :avatar_url'
    assert_includes form_partial_source, "FlatPack::Comments::Composer::Component.new("
    assert_includes form_partial_source, "rich_text_comment_editor_options(placeholder: \"Write your comment...\")"
    assert_includes form_partial_source, "rich_text: rich_text_comments_enabled"
    refute_includes form_partial_source, "force_composer = local_assigns.fetch(:force_composer, false)"
    refute_includes form_partial_source, "rich_text_comments_enabled && force_composer"
    refute_includes form_partial_source, "FlatPack::TextArea::Component.new("
    assert_includes scenarios_view_source, 'text: "Open comment feed"'
    assert_includes scenarios_view_source,
                    'link_to recording_comments_path(recording, return_to: scenarios_path(anchor: "comment-scenarios"))'
    assert_includes scenarios_view_source, "They can open the feed, but cannot add a comment."
    refute_includes scenarios_view_source, 'text: "Post comment"'
    refute_includes scenarios_view_source, "form_with model: @new_comment"
    refute_includes dummy_home_controller_source, "@new_comment = RecordingStudioCommentable::Comment.new"
    assert_includes dummy_home_index_source,
                    "open the scenarios page to inspect each comment feed and verify access outcomes"
    assert_includes dummy_home_index_source, "<strong>View:</strong> view@admin.com / Password"
    assert_includes comment_partial_source, "local_assigns[:parent_recording] || @parent_recording"
    assert_includes comment_partial_source, "local_assigns[:reply_button_resolver]"
    assert_includes comment_partial_source, "local_assigns.fetch(:allow_reply, true)"
    assert_includes comment_partial_source, "FlatPack::Comments::Item::Component.new("
    assert_includes comment_partial_source,
                    "link_to reply_action_options[:text], reply_action_options[:href], class: reply_action_options[:class], data: reply_action_options[:data]"
    assert_includes comment_partial_source, "FlatPack::Button::Component.new(**reply_action_options)"
    assert_includes comment_partial_source, "comment.respond_to?(:author_avatar_url) ? comment.author_avatar_url : nil"
    assert_includes comment_partial_source, "avatar: { name: author_name, src: author_avatar_url }"
    assert_includes comment_partial_source, "FlatPack::RichTextSanitizer.sanitize(comment.body.to_s).html_safe"
    assert_includes comment_partial_source, 'text: "Reply"'
    assert_includes comment_partial_source, "recording_studio_commentable.reply_comment_path"
    assert_includes comment_partial_source, 'class: "text-sm font-medium text-[var(--color-primary)] hover:underline"'
    assert_includes comment_partial_source, 'data: { turbo_frame: "_top" }'
    assert_includes comment_partial_source, "elsif allow_reply"
    assert_includes comment_partial_source, "allow_reply: false"
    assert_includes comment_partial_source, "reply_button_resolver: reply_button_resolver"
    refute_includes comment_partial_source, 'text: "Show"'
    refute_includes comment_partial_source, 'text: "Edit"'
    refute_includes comment_partial_source, 'text: "Delete"'
  end

  def test_dummy_seed_source_includes_view_only_user_for_public_comment_page
    seeds_source = read_workspace_file("test/dummy/db/seeds.rb")
    session_view_source = read_workspace_file("test/dummy/app/views/devise/sessions/new.html.erb")

    assert_includes seeds_source, 'viewer = User.find_or_initialize_by(email: "view@admin.com")'
    assert_includes seeds_source, 'viewer.avatar_url = "https://i.pravatar.cc/160?u=view@admin.com"'
    assert_includes seeds_source, "public_page_recording => [[user, :edit], [quinn, :edit], [viewer, :view]]"
    assert_includes seeds_source, "RecordingStudioCommentable::Services::CreateComment.call("
    assert_includes seeds_source,
                    'body: "Welcome to the shared thread. Use this page to verify the default comments feed with seeded content."'
    assert_includes seeds_source,
                    'body: "Reply sample: Quinn can respond here, which makes the feed show a threaded conversation immediately."'
    assert_includes seeds_source, 'puts "Seeded: view@admin.com / Password"'
    assert_includes seeds_source, 'puts "Seeded: Sample comments for the scenario pages"'
    assert_includes session_view_source, 'text: "View-only: view@admin.com / Password"'
  end

  private

  def read_workspace_file(path)
    File.read(File.expand_path("../#{path}", __dir__))
  end
end
