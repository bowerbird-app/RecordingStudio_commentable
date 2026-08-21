# RecordingStudioCommentable

A Rails engine that adds threaded comment feeds to any [RecordingStudio](https://github.com/bowerbird-app/RecordingStudio) recordable. Comments are modelled as child recordings, giving you full revision history, access control, and trash/restore for free.

## Features

- **Opt-in per recordable** — include `RecordingStudio::Capabilities::Commentable.to` on the types that should have comment feeds. Installing the gem does not turn comments on.
- **RecordingStudio-native** — comments are child recordings; create/update/delete go through the `record`/`revise`/`trash` API
- **Access-control aware** — integrates with `RecordingStudioAccessible` roles (view, edit, manage) when available
- **FlatPack UI** — all views built with FlatPack components; no raw HTML needed
- **Service objects** — `CreateComment`, `UpdateComment`, `DestroyComment` encapsulate business logic
- **Hook system** — lifecycle hooks (`before_initialize`, `after_initialize`, `on_configuration`, `before_service`, `after_service`, `around_service`) for host-app customisation

## What's Included

- **RecordingStudio** gem installed and configured
- **Devise** authentication with a pre-seeded admin user
- **Workspace** root recording set up following RecordingStudio's Quick Start pattern
- **FlatPack** UI component library for all views
- **Dummy app** (`test/dummy/`) with a working login screen, Recording Studio default layout, and sample Page (commentable) and Folder (not commentable) recordables

## Installation

Add to your host application's Gemfile:

```ruby
gem "recording_studio_commentable"
```

Run the install generator:

```bash
rails generate recording_studio_commentable:install
rails generate recording_studio_commentable:migrations
rails db:migrate
```

## Setup

### 1. Opt a recordable into comments

Installing this gem registers `:commentable`. It does not enable it. Opt each recordable type in explicitly:

```ruby
class Page < ApplicationRecord
  recording_studio_recordable(
    label: "Page",
    plural_label: "Pages",
    root: true
  )

  include RecordingStudio::Capabilities::Commentable.to
end
```

Parent rules stay on `recording_studio_recordable`. `include RecordingStudioCommentable::Commentable` still works and calls through to the same `.to` path.

### 2. Register the recordable type with RecordingStudio

```ruby
# config/initializers/recording_studio.rb
RecordingStudio.configure do |config|
  config.recordable_types += ["Page"]
end
```

`RecordingStudioCommentable::Comment` is registered by the addon itself as a capability-owned child recordable in
RecordingStudio 4.2.0+. Host apps only need to register their own parent recordable types and declare them with
`recording_studio_recordable(...)`.

### 3. Add the routes

```ruby
# config/routes.rb
# The install generator adds this mount for you.
mount RecordingStudioCommentable::Engine, at: "/commentable"

scope module: :recording_studio_commentable do
  resources :recordings, only: [] do
    resources :comments, only: %i[index new create edit update destroy] do
      collection do
        get :all, path: "all"
      end
    end
  end
end
```

The mounted engine provides internal pages such as `/commentable`, while the host-app `recording_comments_path(recording)` helpers come from the nested `resources :recordings` routes above.

### 4. Link to the comment feed

```erb
<%= link_to "Comments",
      recording_comments_path(recording) %>
```

The `recording` argument must be the `RecordingStudio::Recording` for the item being commented on.

Or render the built-in widget button:

```erb
<%= render RecordingStudioCommentable::CommentsButton::Component.new(
  recording: recording
) %>
```

The widget routes to the full comments page, disables itself when the current actor cannot view comments, and auto-counts top-level comments plus nested replies. Pass `count:` when you already have a precomputed total.

## Access Control

When `RecordingStudioAccessible` is loaded, the following role checks apply:

| Action | Required role |
|--------|---------------|
| View comment feed | `view` |
| Post a comment | `edit` |
| Edit/delete any comment | `manage` |
| Edit own comment | always allowed (author) |

If `RecordingStudioAccessible` is not loaded, access checks are skipped and all authenticated users can perform all actions.

## Comment Model

```
recording_studio_comments
  id            uuid
  body          text (not null)
  author_type   string (polymorphic)
  author_id     uuid  (polymorphic)
  created_at    datetime
  updated_at    datetime
```

## Service Objects

```ruby
# Create a comment under a recording
result = RecordingStudioCommentable::Services::CreateComment.call(
  parent_recording: recording,
  body: "Great work!",
  author: current_user
)

# Update via the revise pattern
result = RecordingStudioCommentable::Services::UpdateComment.call(
  comment_recording: comment_recording,
  root_recording: root,
  body: "Updated text",
  actor: current_user
)

# Soft-delete (trash) a comment
result = RecordingStudioCommentable::Services::DestroyComment.call(
  comment_recording: comment_recording,
  root_recording: root,
  actor: current_user
)
```

## Configuration

```ruby
RecordingStudioCommentable.configure do |config|
  config.timeout = 5
  config.use_recording_studio_trashable_for_destroy = false
  # config.layout = "recording_studio/default_layout"
  config.rich_text_comments = :toolbar
  config.recordable_display_attributes = {
    "Page" => :title,
    "Event" => :event_name
  }
  config.author_display_attributes = {
    "User" => :full_name,
    "SystemActor" => :display_name
  }
  config.author_avatar_attributes = {
    "User" => :avatar_url
  }

  # Lifecycle hooks
  config.hooks.after_initialize { Rails.logger.info "Commentable ready!" }
  config.hooks.around_service do |_service, block|
    Sentry.with_scope { block.call }
  end
end
```

Leave `config.layout` unset to use Recording Studio's default layout (back and close). Set it to a host layout path when you want the comment pages and `/commentable` home feed to render inside your app shell.

Set `config.use_recording_studio_trashable_for_destroy` to `true` only when the host app installs and configures `recording_studio_trashable` and wants comment deletion to call `recording_studio_trashable_trash!` on the comment recording. The default is `false`, which keeps the existing `RecordingStudio` trash or direct-destroy fallback behavior. If this option is `true` and the comment recording does not support `recording_studio_trashable_trash!`, comment deletion now fails with a clear configuration error instead of silently falling back.

Set `config.rich_text_comments` to `false`, `:toolbar`, or `:selection`. `:toolbar` keeps the visible editor toolbar, while `:selection` hides it and uses the selection bubble menu instead. `true` is still accepted as a backwards-compatible alias for `:toolbar`.

## Quick Start (Dummy App)

### GitHub Codespaces (Recommended)

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for setup to complete
3. Run:
   ```bash
   cd test/dummy
   bin/rails db:setup
   bin/dev
   ```
4. Open port 3000 — you'll see the login screen

The dummy app includes FlatPack generator output and a pre-seeded Page recordable with comments enabled.

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password          |

The login form is prefilled with these credentials for fast access.

## Architecture

### Root Recording Pattern

This template follows RecordingStudio's root recording pattern:

- **Workspace** is the top-level recordable
- A root `RecordingStudio::Recording` wraps the Workspace
- The admin user has root-level admin access via `RecordingStudio::Access`
- `Current.actor` is set from `current_user` (Devise) in `ApplicationController`

### Extending RecordingStudio

To add new recordable types:

1. Create your model (e.g., `Page`, `Comment`)
2. Register it in `config/initializers/recording_studio.rb`:
   ```ruby
   RecordingStudio.configure do |config|
     config.recordable_types = ["Workspace", "YourNewType"]
   end
   ```
3. Leave optional behavior off by default, then opt into capabilities on the specific recordable models that need them:
   ```ruby
   class YourNewType < ApplicationRecord
     include RecordingStudio::Capabilities::Commentable.to
   end
   ```
4. If you want per-device root persistence, wire it explicitly in your controller layer:
   ```ruby
   class ApplicationController < ActionController::Base
     include RecordingStudio::Concerns::DeviceSessionConcern
   end
   ```
5. Create recordings under the root:
   ```ruby
   root_recording.record(YourNewType) do |record|
     record.title = "Example"
   end
   ```

### Capabilities

Comments are off until you enable them on a recordable type:

```ruby
class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: true

  include RecordingStudio::Capabilities::Commentable.to
end
```

Installing `recording_studio_commentable` registers `:commentable` at boot. It does not enable it.

### FlatPack UI Components

All views use FlatPack ViewComponents. Available components include:

- `FlatPack::Button::Component` — Buttons (`:primary`, `:secondary`, `:ghost`)
- `FlatPack::Card::Component` — Cards (`:default`, `:elevated`, `:outlined`)
- `FlatPack::Alert::Component` — Alerts (`:success`, `:error`, `:warning`, `:info`)
- `FlatPack::Badge::Component` — Status badges
- `FlatPack::Table::Component` — Data tables
- `FlatPack::TextInput::Component`, `EmailInput`, `PasswordInput` — Form inputs
- `FlatPack::Breadcrumb::Component` — Navigation breadcrumbs
- `FlatPack::Navbar::Component` — Navigation sidebar

See the [FlatPack README](https://github.com/bowerbird-app/flatpack) for full documentation.

## Tech Stack

| Component       | Version |
|-----------------|---------|
| Ruby            | 3.3+    |
| Rails           | 8.1+    |
| PostgreSQL      | 16      |
| TailwindCSS     | 4       |
| RecordingStudio | v4.2.0 (pinned in `Gemfile` and `test/dummy/Gemfile`) |
| FlatPack        | v0.1.33 (pinned in `test/dummy/Gemfile`) |
| Devise          | latest  |

## Documentation

For a host-app focused walkthrough of installation, request flow, service methods, and hooks, see [docs/RS_COMMENTABLE_GUIDE.md](docs/RS_COMMENTABLE_GUIDE.md). Upgrade notes for 0.3.0 live in [docs/UPGRADING.md](docs/UPGRADING.md).

The original gem template documentation is preserved in `docs/gem_template/` as architectural reference material. Use it as background on the engine conventions; the README and dummy app are the source of truth for the Recording Studio addon workflow.
