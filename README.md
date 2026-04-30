# RecordingStudioCommentable

A Rails engine that adds threaded comment feeds to any [RecordingStudio](https://github.com/bowerbird-app/RecordingStudio) recordable. Comments are modelled as child recordings, giving you full revision history, access control, and trash/restore for free.

## Features

- **Opt-in per recordable** — include `RecordingStudioCommentable::Commentable` in any model to enable comment feeds
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
- **Dummy app** (`test/dummy/`) with a working login screen, FlatPack sidebar layout, and sample Page (commentable) and Folder (not commentable) recordables

## Installation

Add to your host application's Gemfile:

```ruby
gem "recording_studio_commentable"
```

Run the install generator:

```bash
rails generate recording_studio_commentable:install
rails recording_studio_commentable:install:migrations
rails db:migrate
```

## Setup

### 1. Opt a recordable into comments

```ruby
class Page < ApplicationRecord
  include RecordingStudioCommentable::Commentable
end
```

### 2. Register the recordable type with RecordingStudio

```ruby
# config/initializers/recording_studio.rb
RecordingStudio.configure do |config|
  config.recordable_types += ["Page", "RecordingStudioCommentable::Comment"]
end
```

### 3. Mount the engine

```ruby
# config/routes.rb
mount RecordingStudioCommentable::Engine, at: "/commentable"
```

### 4. Link to the comment feed

```erb
<%= link_to "Comments",
      recording_studio_commentable.recording_comments_path(recording) %>
```

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

  # Lifecycle hooks
  config.hooks.after_initialize { Rails.logger.info "Commentable ready!" }
  config.hooks.around_service do |_service, block|
    Sentry.with_scope { block.call }
  end
end
```

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
     include RecordingStudio::Capabilities::Movable.to("Workspace")
     include RecordingStudio::Capabilities::Copyable.to("Workspace")
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

This template uses the current RecordingStudio approach: built-in capabilities are off by default and are enabled per recordable type by including the relevant module on the model.

- `movable`
- `copyable`

Device session persistence is separate from capabilities. It is enabled only when you include `RecordingStudio::Concerns::DeviceSessionConcern` in your controller layer.

Enable behavior intentionally where it belongs:

```ruby
class RecordingStudioPage < ApplicationRecord
  include RecordingStudio::Capabilities::Movable.to("Workspace")
  include RecordingStudio::Capabilities::Copyable.to("Workspace")
end

class ApplicationController < ActionController::Base
  include RecordingStudio::Concerns::DeviceSessionConcern
end
```

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
| RecordingStudio | v0.1.0-alpha (pinned in `test/dummy/Gemfile`) |
| FlatPack        | v0.1.33 (pinned in `test/dummy/Gemfile`) |
| Devise          | latest  |

## Documentation

The original gem template documentation is preserved in `docs/gem_template/` as architectural reference material. Use it as background on the engine conventions; the README and dummy app are the source of truth for the Recording Studio addon workflow.
