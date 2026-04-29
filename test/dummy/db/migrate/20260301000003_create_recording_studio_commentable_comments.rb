# frozen_string_literal: true

class CreateRecordingStudioCommentableComments < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_commentable_comments, id: :uuid do |t|
      t.text :body, null: false

      t.string :author_type
      t.uuid   :author_id

      t.integer :recordings_count, default: 0, null: false

      t.timestamps
    end

    add_index :recording_studio_commentable_comments, %i[author_type author_id],
              name: "idx_rsc_comments_on_author"
  end
end
