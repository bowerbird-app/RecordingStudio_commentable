# Upgrade Guide

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
