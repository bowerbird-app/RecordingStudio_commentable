# frozen_string_literal: true

require "test_helper"

class RecordingStudioCommentableTest < Minitest::Test
  def test_version_exists
    refute_nil ::RecordingStudioCommentable::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioCommentable::Engine
  end

  def test_dummy_app_uses_flatpack_sidebar_layout
    layout_path = File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__)
    assert File.exist?(layout_path)

    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)
    assert_includes controller_source, "flat_pack_sidebar"
  end

  def test_dummy_pseudo_top_nav_layout_exists_for_commentable_layout_config
    layout_path = File.expand_path("dummy/app/views/layouts/flat_pack_pseudo_top_nav.html.erb", __dir__)
    assert File.exist?(layout_path)

    layout_source = File.read(layout_path)
    assert_includes layout_source, 'render "layouts/flat_pack/top_nav"'
    assert_includes layout_source, "Pseudo layout preview"
  end

  def test_engine_uses_its_own_layout_without_dummy_sidebar_shell
    layout_path = File.expand_path("../app/views/layouts/recording_studio_commentable/application.html.erb", __dir__)
    assert File.exist?(layout_path)

    layout_source = File.read(layout_path)
    assert_includes layout_source, 'stylesheet_link_tag "flat_pack/application"'
    refute_includes layout_source, "FlatPack::SidebarLayout::Component"
    refute_includes layout_source, 'render "layouts/flat_pack/top_nav"'
  end

  def test_recording_studio_capabilities_are_off_by_default
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "Built-in capabilities remain disabled"
    refute_includes initializer_source, "config.features."
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "This Rails app exists to validate the Recording Studio addon template"
    assert_includes readme_source, "/recording_studio"
  end

  def test_dummy_home_page_mentions_template_workflow
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "Scenario matrix"
    assert_includes view_source, "Workspace state"
    assert_includes view_source, "/scenarios"
  end

  def test_dummy_scenarios_page_uses_flatpack_components
    view_path = File.expand_path("dummy/app/views/home/scenarios.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, "FlatPack::PageTitle::Component"
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "FlatPack::Badge::Component"
  end

  def test_engine_home_page_lists_comments_without_dummy_sidebar_shell
    view_path = File.expand_path("../app/views/recording_studio_commentable/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, 'title: "Recording Studio Commentable"'
    assert_includes view_source, 'subtitle: "All comments"'
    assert_includes view_source, 'render "comments_page"'
  end

  def test_dummy_routes_expose_scenarios_page
    routes_path = File.expand_path("dummy/config/routes.rb", __dir__)
    routes_source = File.read(routes_path)

    assert_includes routes_source, 'get "/scenarios", to: "home#scenarios", as: :scenarios'
  end

  def test_dummy_sidebar_lists_scenario_and_commentable_links
    sidebar_path = File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__)
    sidebar_source = File.read(sidebar_path)

    assert_includes sidebar_source, 'label: "Scenario"'
    assert_includes sidebar_source, 'href: "/scenarios"'
    assert_includes sidebar_source, 'label: "Commentable"'
    assert_includes sidebar_source, 'href: "/commentable"'
  end

  def test_commentable_module_exists
    assert_kind_of Module, ::RecordingStudioCommentable::Commentable
  end

  def test_configure_yields_configuration
    yielded = nil
    RecordingStudioCommentable.configure { |c| yielded = c }
    assert_kind_of RecordingStudioCommentable::Configuration, yielded
  end
end
