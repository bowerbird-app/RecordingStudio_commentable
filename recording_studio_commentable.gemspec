# frozen_string_literal: true

require_relative "lib/recording_studio_commentable/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_commentable"
  spec.version     = RecordingStudioCommentable::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_commentable"
  spec.summary     = "Threaded comments addon for Recording Studio"
  spec.description = "A Rails engine that adds threaded comment feeds to any Recording Studio " \
                     "recordable, with FlatPack UI, access-control integration, and " \
                     "immutable-revision semantics via the RecordingStudio record/revise API."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/RecordingStudio_commentable"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/RecordingStudio_commentable/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "recording_studio", "~> 4.2"
end
