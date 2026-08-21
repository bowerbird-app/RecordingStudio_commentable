# RecordingStudioCommentable Install

Run the following after bundling:

```
rails generate recording_studio_commentable:install
rails generate recording_studio_commentable:migrations
rails db:migrate
```

The install generator mounts the engine at `/commentable`. Add the recording-scoped host routes if your app does not already define them:

```ruby
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

Then include Commentable.to on your recordable:

```ruby
class Page < ApplicationRecord
  include RecordingStudio::Capabilities::Commentable.to
end
```

And add your recordable type to the RecordingStudio initializer. The addon registers `RecordingStudioCommentable::Comment` itself:

```ruby
RecordingStudio.configure do |config|
  config.recordable_types += ["Page"]
end
```

Link to the comment feed from your views:

```erb
<%= link_to "Comments", recording_comments_path(recording) %>
```
