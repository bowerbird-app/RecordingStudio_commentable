# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-09-02

Cloud Agent install no longer fails a warm environment rebuild. Skills still
fetch at Build. Product comments are unchanged.

### Added
- Cloud Agent boot files matching RecordingStudio_billing v0.9.13:
  `.cursor/environment.json`, `.cursor/install.sh`, `.cursor/fetch-skills.sh`,
  and `.cursor/start.sh`

### Fixed
- `.cursor/install.sh` skips apt, ruby-build, db:prepare, and tailwind when
  Ruby, bundle, and Postgres are already usable. A skippable provision
  failure no longer fails the Build. Fetch-skills always runs last.

### Upgrade notes
- No host or schema changes. Rebuild the Cloud Agent environment with Draft
  off so Build loads the pack.

## [0.3.0] - 2026-08-21

### Added
- Canonical host verb `include RecordingStudio::Capabilities::Commentable.to(**opts)`, a thin wrapper around Recording Studio 4.2 `Capabilities.include_for(:commentable, **options)`
- Option validation stays in this gem; `.to` does not register the capability

### Changed
- Requires Recording Studio `~> 4.2` (Gemfile and dummy pin `v4.2.0`)
- Dummy Page enables comments with `.to`; Folder and Workspace stay off
- Dummy and engine screens use Recording Studio's default layout and Flatpack PageNav
- `include RecordingStudioCommentable::Commentable` remains an alias that calls through to `.to`
- Without `recording_studio_trashable`, deleting a comment purges the recording tree because 4.x recordables cannot be destroyed through Active Record
- CI inherits `.rubocop_todo.yml` for pre-existing style offenses so the suite can run

### Upgrade notes
See [docs/UPGRADING.md](docs/UPGRADING.md).

## [0.1.1] - 2026-04-28

### Changed
- Bumped the dummy app FlatPack dependency from `0.1.2` to `0.1.33` and pinned it by tag in `test/dummy/Gemfile`

## [0.1.0] - 2025-12-04

### Added
- Initial release
- Rails mountable engine structure
- PostgreSQL with UUID primary keys support
- TailwindCSS v4 integration
- GitHub Codespaces devcontainer configuration
- Docker Compose setup with PostgreSQL and Redis
- Install generator for host applications
- Comprehensive README and documentation
- Basic test suite with Minitest

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_commentable/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.3.1
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.3.0
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.1.0
