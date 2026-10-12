# Upgrade Guide

## Upgrading to 0.5.0

Wave 2 finishes host-overridable copy outside views: controller flash
notices/alerts, composer headings, service error strings, and display labels
passed at render/call sites. Keys stay under `recording_studio.commentable.*`.
English output is unchanged.

### Upgrade steps

1. Install Commentable `0.5.0`. No migration.
2. Copy new `recording_studio.commentable.flashes.*`, `errors.*`, and
   `display.*` keys into host locale files when translating.
3. Hosts override by defining the same nested keys in their own
   `config/locales`. `Comment#author_display_name` still returns the literal
   `"Anonymous"`; the comment partial translates that case via
   `t("recording_studio.commentable.common.anonymous", default: "Anonymous")`.
   `recordable_display_title` still defaults to literal `"Unknown item"`;
   callers pass `missing: t("recording_studio.commentable.display.*", default: ...)`.
   `CommentsFeed::Component::DEFAULT_REPLY_BUTTON_OPTIONS` remains.
4. There is no dependency on `recording_studio_internationalization`.

When a service failure string is added via `errors.add(:base, result.error)`,
`errors.details` carries that translated string in non-English locales
(ActiveModel String error types).

Intentionally left untranslated: comment bodies and other database content,
`recording_studio_recordable label:` / `plural_label:` (class-load DSL),
`Comment#author_display_name` / `recordable_display_title` return values
(translated at render), comment timestamp `strftime` output, generator CLI
text, developer `ArgumentError` / trashable-integration messages, icon/style
tokens, and dummy app views.

## Upgrading to 0.4.0

Static interface copy in this gem's own views, partials, components, and engine
layout now resolves through Rails I18n under `recording_studio.commentable`.
English is the only locale shipped by the gem. Rendered English output is
unchanged.

### Upgrade steps

1. No migration or host code change is required for English.
2. To translate or override the defaults, add keys under
   `recording_studio.commentable` in the host's locale files.
3. There is no dependency on `recording_studio_internationalization`.

Controller flash notices/alerts, service errors, and anonymous author labels
moved to I18n in 0.5.0. Comment bodies and other database content,
caller-provided titles/labels, icon/style tokens, and dummy app views stay
host-owned.

## Upgrading to 0.3.1

No host or schema changes. Comment enablement, services, and screens stay on
the 0.3.0 contract.

If you use Cloud Agents on this repository, rebuild the environment with Draft
off so Build runs `.cursor/install.sh` and loads the fetched skill pack. See
[Cursor skills in Cloud Agents](cursor-skills.md).

## Upgrading to 0.3.0

This release pins Recording Studio 4.2 and switches comment enablement to the core factory.

### What changed

- The host verb is `include RecordingStudio::Capabilities::Commentable.to(**opts)`.
- `.to` wraps `RecordingStudio::Capabilities.include_for(:commentable, **options)`.
- Installing the gem still only registers `:commentable`. It does not enable comments on every recordable.
- Parent rules stay on `recording_studio_recordable`.
- `include RecordingStudioCommentable::Commentable` still works and calls through to `.to`.
- Comment screens use Recording Studio's default layout unless you set `config.layout`.
- Recordables are immutable in Recording Studio 4.x. Without `recording_studio_trashable`, deleting a comment purges that recording (and its comment snapshots) instead of calling `destroy!` on the comment row.

### Upgrade steps

1. Upgrade Recording Studio to `4.2.0` or newer (`~> 4.2`).
2. Run the Recording Studio harden migration if you have not already:

```bash
rails g recording_studio:migrations
rails db:migrate
```

3. Enable comments on each recordable type that should have them:

```ruby
class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: true

  include RecordingStudio::Capabilities::Commentable.to
end
```

No commentable database migration is required for this release.
