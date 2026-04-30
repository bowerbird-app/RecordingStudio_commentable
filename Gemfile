# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_commentable.gemspec
gemspec

# recording_studio is a hard dependency declared in the gemspec.
# Because it is hosted on GitHub (not rubygems.org), it must also be listed
# here so bundler can resolve it in the development/test environment.
gem "recording_studio", github: "bowerbird-app/RecordingStudio", tag: "v0.1.0-alpha"

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
