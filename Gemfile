# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_commentable.gemspec
gemspec

# recording_studio is a hard dependency declared in the gemspec.
# Because it is hosted on GitHub (not rubygems.org), it must also be listed
# here so bundler can resolve it in the development/test environment.
gem "flat_pack", github: "bowerbird-app/flatpack", tag: "v0.1.329", require: false
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v6.3.0"
gem "recording_studio_accessible", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.22.2"
# Trashable gemspec deps are git-only; pin for Bundler resolution only.
gem "recording_studio_metrics", github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.7.0", require: false
# Accessible 0.17 loads trashable query-only; pin by tag with require: false.
gem "recording_studio_trashable", github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.12.0", require: false

gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
