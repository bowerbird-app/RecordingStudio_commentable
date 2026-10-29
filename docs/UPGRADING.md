# Upgrade Guide

## Upgrading to 0.6.3

Commentable works with Recording Studio 6.1 and newer. Dummy and CI pin core
`v6.3.0` and FlatPack `v0.1.329`.

### Upgrade steps

1. Install Commentable `0.6.3` with `recording_studio` `>= 4.2, < 7`. Run the
   dummy on Recording Studio `v6.3.0` and FlatPack `v0.1.329`. No migration.
2. Leave `config.layout` unset unless this gem's screens should use a
   different layout than `RecordingStudio.configuration.layout`. Accepted
   values are `nil`, `false`, a layout name, or a callable invoked as
   `call(controller:)`.
3. Replace `recording_studio_page_nav` with `content_for :title`,
   `content_for :subtitle`, and `flat_pack_page_nav`. Put page actions on
   `register_page_nav`. `recording_studio_page_nav_right` is available again
   on core 6.1+.
4. Replace FlatPack `Button` `url:` with `href:`. Remove Card `style:`.

Stay on Commentable `0.6.2` if the host is still on Recording Studio 4.

## Upgrading to 0.6.2

No host or schema changes. Comment enablement, services, and screens stay on
the 0.6.0 contract.

Git tag `v0.6.1` already existed for the Trashable `v0.11.0` companion pin
while `version.rb` still said `0.6.0`, so this release is `0.6.2`.

### Upgrade steps

1. Install Commentable `0.6.2`. No migration.
2. Host apps need no code change.
3. Dummy / development companion pins already use Trashable `v0.11.0` from the
   `v0.6.1` tag. Hosts that pin that companion can stay on `v0.11.0`.

## Upgrading to 0.6.1

No Commentable API or schema change. The git tag `v0.6.1` recorded the
Trashable companion pin to `v0.11.0` (#24) without bumping `version.rb`.

### Upgrade steps

1. No Commentable install step was published from `version.rb` for this tag.
2. Hosts that pin `recording_studio_trashable` as an Accessible query-only
   companion can use tag `v0.11.0`.

## Upgrading to 0.6.0

Missing `recording_studio.commentable.*` keys fall back through
`RecordingStudio.t`: loaded `:en` (host English overrides included), then the
caller's `default:`, then the merged gem-shipped English table. This gem
registers `config/locales/en.yml` at boot via
`RecordingStudio::Translation.register_shipped_english`. English output is
unchanged. `en.yml` is byte-identical to 0.5.0.

### Upgrade steps

1. Install Commentable `0.6.0` and `recording_studio ~> 4.7`. No migration.
2. Host apps need no change for English. Prefer `RecordingStudio.t` only for
   this gem's `recording_studio.commentable.*` keys so missing locales keep the
   same fallback. Host or other-namespace keys stay on `I18n.t` / `t` with
   main's `default:` where they had one.
3. Hosts that enable raise-on-missing translations no longer raise for
   gem-shipped `recording_studio.commentable.*` keys looked up through
   `RecordingStudio.t` when loaded `:en` or the gem-shipped table has the key.
   Host overrides in the active locale still win; host `:en` overrides win on
   the loaded-English fallback step.
4. A missing `_html` key with a non-interpolating String caller `default:`
   stays unsafe like view `t`: a plain default with no interpolation is
   returned as a plain (non-html_safe) String, so views will escape it. An
   interpolating String caller `default:` escapes args and returns `html_safe`
   (stricter than view `t`). An Array caller `default:` on a missing `_html`
   key is also marked `html_safe` by `RecordingStudio.t` (stricter than view
   `t`).
5. There is no dependency on `recording_studio_internationalization`.

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
