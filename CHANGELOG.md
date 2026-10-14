# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-10-14

### Added
- English fallback for shipped `recording_studio.commentable.*` keys when the
  active locale has no translation: call sites use `RecordingStudio.t`, and the
  engine registers `config/locales/en.yml` via
  `RecordingStudio::Translation.register_shipped_english` so fallback comes
  from the loaded English, host overrides included, then the merged gem-shipped
  table
- Behavioral coverage for parity vs `I18n.t`, fallback order, `_html` escaping,
  boot registration, reloader reset, drift guard (no hand-copied English
  `default:`), and real-page deleted-key / boot-override renders

### Changed
- Version `0.5.0` → `0.6.0`.
- Depends on `recording_studio ~> 4.7`.
- Only this gem's `recording_studio.commentable.*` call sites look up copy
  through `RecordingStudio.t` (hand-copied English `default:` removed;
  `en.yml` unchanged). Host or other-namespace keys stay on their original
  `I18n.t` / `t` with main's `default:` where they had one.

### Upgrade notes
- Install Commentable `0.6.0` with `recording_studio ~> 4.7`. No migration.
  English hosts need no change. See [docs/UPGRADING.md](docs/UPGRADING.md).
- Prefer `RecordingStudio.t` only for `recording_studio.commentable.*` keys.
  Host or other-namespace keys stay on `I18n.t` / `t` with main's `default:`
  where they had one.
- A missing `_html` key with a non-interpolating String caller `default:` stays
  unsafe like view `t`: a plain default with no interpolation is returned as a
  plain (non-html_safe) String, so views will escape it. An interpolating String
  caller `default:` escapes args and returns `html_safe` (stricter than view
  `t`). An Array caller `default:` on a missing `_html` key is also marked
  `html_safe` by `RecordingStudio.t` (stricter than view `t`, which leaves
  Array defaults unsafe).

## [0.5.0] - 2026-10-12

### Added
- English Rails I18n keys for controller flash notices/alerts, composer
  headings, service error strings, anonymous author label, and missing-item
  display labels under `recording_studio.commentable.flashes.*`,
  `errors.*`, and `display.*`
- Locale regression: every `lib/**/*.rb` file must not mention
  `i18n.load_path` / `I18n.load_path`. Unit tests seed gem English via
  `I18n.backend.store_translations`
- Render-level literal-English asserts for Add comment / Comment added. /
  Body cannot be blank / Anonymous (alongside `comments_pages_flow_test`
  source greps)

### Changed
- Version `0.4.1` → `0.5.0`.
- Controller notices/alerts, composer titles, and Create/UpdateComment failure
  strings resolve through `t(..., default: <main English>)` (English output
  unchanged).
- Anonymous author copy and missing-item titles translate at render/call sites
  (`_comment` partial / `missing:` args). Public
  `Comment#author_display_name` and `recordable_display_title` keep main’s
  literal English return values (`"Anonymous"`, default `missing: "Unknown item"`).
- When a translated service failure string is added as
  `errors.add(:base, result.error)`, `errors.details` carries that translated
  string in non-English locales (ActiveModel String error types).

### Upgrade notes
See [docs/UPGRADING.md](docs/UPGRADING.md).

## [0.4.1] - 2026-10-09

### Fixed
- Restored `CommentsFeed::Component::DEFAULT_REPLY_BUTTON_OPTIONS` as a
  backward-compatible alias of `DEFAULT_REPLY_BUTTON_STYLE` with `text: "Reply"`
- Corrected the 0.4.0 CHANGELOG Recording Studio pin note to `v4.4.0` (was
  stale `v4.2.2`)
- Removed the engine `i18n.load_path` append so host locale files load after
  the gem and can override English defaults

### Changed
- Version `0.4.0` → `0.4.1`.

## [0.4.0] - 2026-10-09

### Added
- English Rails I18n keys for static interface copy in the gem's own views,
  partials, components, and engine layout (`config/locales/en.yml` under
  `recording_studio.commentable`)

### Changed
- Version `0.3.1` → `0.4.0`.
- Comment screens, feed/composer components, and the engine layout resolve
  static chrome through `t("recording_studio.commentable...")` (English output
  unchanged).
- Bumped Recording Studio pin from `v4.2.0` to `v4.4.0` in `Gemfile` and `test/dummy/Gemfile`
- Bumped `recording_studio_accessible` pin from `v0.6.0` to `v0.11.1` in `Gemfile` and `test/dummy/Gemfile`
- Dummy app now installs Accessible `0.8`–`0.11` migrations (`depends_on`, invitations, string `role`) and seeds grants through `bootstrap_owner_access!` / `grant_access`
- Gem tests restore `Object#stub` for Minitest 6 (pulled in by the Rails patch bump)

### Upgrade notes
See [docs/UPGRADING.md](docs/UPGRADING.md).

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_commentable/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/bowerbird-app/RecordingStudio_commentable/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_commentable/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.4.1
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.4.0
[0.3.1]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.3.1
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.3.0
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_commentable/releases/tag/v0.1.0
