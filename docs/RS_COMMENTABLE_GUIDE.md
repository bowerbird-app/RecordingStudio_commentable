# RS Commentable Guide

## What this gem adds

`recording_studio_commentable` adds a comment feed to any model in your Rails app that already lives inside `RecordingStudio`.

The short version is:

- your app keeps owning the real model being commented on, like `Page`
- `RS_commentable` adds the UI, controller flow, and comment services
- `RecordingStudio` stores where the comment lives in the tree and keeps the history of create, edit, and delete actions

So this gem is not a separate comments system sitting beside RecordingStudio. It works through RecordingStudio.

## Installation

Add the gem to your host app:

```ruby
gem "recording_studio_commentable"
```

Then run:

```bash
bundle install
rails generate recording_studio_commentable:install
rails generate recording_studio_commentable:migrations
rails db:migrate
```

The generated initializer keeps rich text comments off by default:

```ruby
RecordingStudioCommentable.configure do |config|
  config.rich_text_comments = false
end
```

Turn that flag on if you want comment forms to use FlatPack's rich text editor and render sanitized HTML in the feed.

What the install generator does:

- mounts the engine in your routes
- creates `config/initializers/recording_studio_commentable.rb`
- tries to add the engine views and FlatPack components to your Tailwind source list

## Host app setup

### 1. Make a model commentable

Include the marker module in any recordable model that should allow comments:

```ruby
class Page < ApplicationRecord
  include RecordingStudioCommentable::Commentable
end
```

This is the main opt-in. If a model does not include this module, the engine will refuse comment actions for it.

### 2. Register the comment recordable with RecordingStudio

In your `RecordingStudio` initializer:

```ruby
RecordingStudio.configure do |config|
  config.recordable_types += ["Page", "RecordingStudioCommentable::Comment"]
end
```

Why this matters:

- `Page` is your app model that receives comments
- `RecordingStudioCommentable::Comment` is the actual comment recordable that RecordingStudio wraps in a recording

### 3. Mount the engine

Your host app needs a mounted route:

```ruby
mount RecordingStudioCommentable::Engine, at: "/commentable"
```

That creates routes like:

```text
/commentable/recordings/:recording_id/comments
```

The comment feed is always attached to a `RecordingStudio::Recording`, not directly to a raw Active Record row.

### 4. Link to the feed

From your app UI, link to the recording's comments page:

```erb
<%= link_to "Comments",
      recording_studio_commentable.recording_comments_path(recording) %>
```

The important part is that `recording` here is a `RecordingStudio::Recording` for the thing being commented on.

## Comment editor mode

By default, comments use a plain textarea.

If you want rich text comments, enable the config flag in your initializer:

```ruby
RecordingStudioCommentable.configure do |config|
  config.rich_text_comments = true
end
```

What changes when this is enabled:

- the new/edit comment form uses FlatPack rich text mode
- comment bodies are stored as HTML
- rendered comments are sanitized through `FlatPack::RichTextSanitizer` before display

## The main flow

## When you open the comments page

If you call:

```erb
recording_studio_commentable.recording_comments_path(recording)
```

the request goes here:

- route: `recordings/:recording_id/comments`
- controller: `RecordingStudioCommentable::CommentsController#index`

What happens next:

1. the controller loads the parent recording from `params[:recording_id]`
2. it checks that the underlying recordable included `RecordingStudioCommentable::Commentable`
3. it checks whether the current actor can view comments there
4. it loads comment recordings under that parent recording
5. it renders the comment feed

The comments are fetched by looking for child `RecordingStudio::Recording` rows whose `recordable_type` is `RecordingStudioCommentable::Comment`.

That means the feed is driven by recordings, with the comment model attached to each recording.

## When you create a comment

If a user posts the new-comment form, the request goes to:

- controller: `CommentsController#create`
- service: `RecordingStudioCommentable::Services::CreateComment.call`

The flow looks like this:

1. the controller loads the parent recording
2. it checks that comments are enabled for that recordable
3. it checks create permission
4. it passes the body and actor into `CreateComment`
5. the service validates the body
6. the service builds a `RecordingStudioCommentable::Comment`
7. the service asks `RecordingStudio` to record that comment as a child of the parent recording
8. the controller redirects back to the feed

In plain terms: a new comment is created as a comment record, then wrapped by RecordingStudio as a child recording under the item you commented on.

## When you edit a comment

Editing goes to:

- controller: `CommentsController#update`
- service: `RecordingStudioCommentable::Services::UpdateComment.call`

The flow is:

1. the controller loads the comment recording
2. it lets the author edit their own comment, or checks for `manage` permission
3. it finds the root recording
4. it passes the comment recording, root recording, new body, and actor into `UpdateComment`
5. the service uses RecordingStudio's `revise` flow
6. RecordingStudio keeps the same recording in place but updates the recordable snapshot

The practical result is: the comment looks edited in the feed, but RecordingStudio still keeps the history.

## When you delete a comment

Deleting goes to:

- controller: `CommentsController#destroy`
- service: `RecordingStudioCommentable::Services::DestroyComment.call`

The flow is:

1. the controller loads the comment recording
2. it checks author-or-manage permission
3. it finds the root recording
4. it passes the comment recording and actor into `DestroyComment`
5. the service calls RecordingStudio's `trash`
6. the feed stops showing that comment because trashed recordings are excluded

This is a soft delete at the recording layer, not a hard wipe of history.

## The three main service methods

Most host apps will not call the services directly from controllers because the engine already does that, but these are the methods that power the behavior.

### CreateComment

```ruby
RecordingStudioCommentable::Services::CreateComment.call(
  parent_recording: recording,
  body: "Nice update",
  author: current_user
)
```

Use this when you want to create a comment under a specific recording.

What it does:

- rejects blank bodies
- builds a `RecordingStudioCommentable::Comment`
- records it under the parent recording when `RecordingStudio` is available

### UpdateComment

```ruby
RecordingStudioCommentable::Services::UpdateComment.call(
  comment_recording: comment_recording,
  root_recording: root_recording,
  body: "Edited text",
  actor: current_user
)
```

Use this when you want to revise an existing comment through RecordingStudio.

What it does:

- rejects blank bodies
- uses `revise` when RecordingStudio is available
- preserves the recording-based history model

### DestroyComment

```ruby
RecordingStudioCommentable::Services::DestroyComment.call(
  comment_recording: comment_recording,
  root_recording: root_recording,
  actor: current_user
)
```

Use this when you want to trash a comment recording.

What it does:

- uses RecordingStudio's `trash`
- removes the comment from the active feed
- leaves history available in RecordingStudio terms

## What methods you are expected to use in the host app

These are the main public methods and entry points you are likely to touch.

### `include RecordingStudioCommentable::Commentable`

Put this on a model to opt it into comments.

### `RecordingStudioCommentable.configure`

Use this in `config/initializers/recording_studio_commentable.rb` to set options and register hooks:

```ruby
RecordingStudioCommentable.configure do |config|
  config.timeout = 5
end
```

### `recording_studio_commentable.recording_comments_path(recording)`

Use this route helper when you want to link users to the comment feed for a recording.

### Service calls

If you are building your own custom UI or background workflow, these are the main callable methods:

- `RecordingStudioCommentable::Services::CreateComment.call`
- `RecordingStudioCommentable::Services::UpdateComment.call`
- `RecordingStudioCommentable::Services::DestroyComment.call`

## Hooks you can use

The gem exposes a small hook system through:

```ruby
RecordingStudioCommentable.configure do |config|
  config.hooks ...
end
```

These are the main hooks.

### `before_initialize`

Runs before the engine finishes its setup.

Good for:

- preparing configuration
- registering behavior very early

```ruby
RecordingStudioCommentable.configure do |config|
  config.hooks.before_initialize do
    Rails.logger.info("RS Commentable is about to initialize")
  end
end
```

### `on_configuration`

Runs after configuration values are loaded and merged.

Good for:

- reacting to final config values
- applying host-app defaults

```ruby
RecordingStudioCommentable.configure do |config|
  config.hooks.on_configuration do |final_config|
    Rails.logger.info("Timeout is #{final_config.timeout}")
  end
end
```

### `after_initialize`

Runs after the engine has finished its initialization phase.

Good for:

- startup logging
- hooking in extra setup after the gem is ready

### `before_service`

Runs before a service object executes.

Good for:

- audit logging
- instrumentation
- lightweight validation around service usage

The hook receives the service class and the service arguments.

```ruby
RecordingStudioCommentable.configure do |config|
  config.hooks.before_service do |service_class, args|
    Rails.logger.info("Starting #{service_class.name} with #{args.inspect}")
  end
end
```

### `after_service`

Runs after a service finishes.

Good for:

- success or failure logging
- metrics
- notifications

The hook receives the service class and the result object.

```ruby
RecordingStudioCommentable.configure do |config|
  config.hooks.after_service do |service_class, result|
    Rails.logger.info("#{service_class.name} success? #{result.success?}")
  end
end
```

### `around_service`

Wraps service execution.

Good for:

- timing
- tracing
- error reporting wrappers
- transaction-like wrappers if that fits your app

```ruby
RecordingStudioCommentable.configure do |config|
  config.hooks.around_service do |_service, next_step|
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    next_step.call
  ensure
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    Rails.logger.info("Commentable service took #{elapsed.round(3)}s")
  end
end
```

## Extension hooks for models and controllers

If you want to attach extra behavior to specific models or controllers, there are two more extension points:

- `config.hooks.extend_model(:ModelName) { ... }`
- `config.hooks.extend_controller(:ControllerName) { ... }`

These are best when you want small host-app customizations without forking the gem.

Example:

```ruby
RecordingStudioCommentable.configure do |config|
  config.hooks.extend_model(:Page) do
    def comments_enabled_for_ui?
      true
    end
  end
end
```

## Authorization flow

If `RecordingStudioAccessible` is present, this gem uses it against the parent recording.

The default role mapping is:

- view feed: `view`
- create comment: `edit`
- edit or delete any comment: `manage`
- edit your own comment: allowed even without `manage`

If `RecordingStudioAccessible` is not installed, those role checks are skipped.

## Mental model to keep in mind

When something feels confusing, this is usually the right way to think about it:

- your app model, like `Page`, is the thing being commented on
- the page has a `RecordingStudio::Recording`
- each comment is its own comment recordable
- each comment recordable is wrapped by its own `RecordingStudio::Recording`
- create, edit, and delete all go through RecordingStudio behavior

So if you ask, "where does this method go?" the answer is usually:

1. route helper or form submits to the engine controller
2. controller loads the relevant recordings and checks permissions
3. controller calls a comment service
4. service delegates the real tree or history action to RecordingStudio

That is the core flow of the gem.