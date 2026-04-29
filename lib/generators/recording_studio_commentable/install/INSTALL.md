# RecordingStudioCommentable Install

Run the following after bundling:

```
rails generate recording_studio_commentable:install
rails recording_studio_commentable:install:migrations
rails db:migrate
```

Then include the Commentable module in your recordable:

```ruby
class Page < ApplicationRecord
  include RecordingStudioCommentable::Commentable
end
```

And add your recordable type to the RecordingStudio initializer:

```ruby
RecordingStudio.configure do |config|
  config.recordable_types += ["Page", "RecordingStudioCommentable::Comment"]
end
```

Link to the comment feed from your views:

```erb
<%= link_to "Comments", recording_studio_commentable.recording_comments_path(recording) %>
```
