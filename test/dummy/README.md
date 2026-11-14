# Dummy App

This Rails app exists to validate the Recording Studio addon template in a real host application.

## What It Covers

- Devise authentication with a seeded admin user
- `Current.actor` wiring for Recording Studio events
- Root workspace and root recording setup
- Recording Studio default layout and FlatPack page chrome
- Mounted `RecordingStudio::Engine` route behavior inside a host app

## Quick Start

```bash
bundle install
bin/rails db:setup
bin/dev
```

Then open the app and sign in with:

- Email: `admin@admin.com`
- Password: `Password`

## Useful Routes

- `/` - dummy app home page and template guidance
- `/recording_studio` - mounted Recording Studio engine
- `/users/sign_in` - Devise sign-in page
- `/up` - Rails health check

## Recording Studio API (dummy-only)

This dummy lets Recording Studio API clients provision so comment JSON tests can run.

- `config.authorize_write` still requires Accessible `:edit` for host writes. Inside `AccessCreationContext` it also lets `RecordingStudioApi::*` recordables through, so token provisioning can write API client and credential rows without opening a comment write hole.
- Dummy `RecordingStudioApi` config sets `api_management_authorization_required = false`. Hosts should keep the API gem default unless they intentionally skip that check.

## Why This App Exists

Use this app to verify the generated addon experience before renaming the gem or copying patterns into another host app. If a layout, route, asset source, or Recording Studio initializer change breaks here, the template likely needs adjustment before reuse.
