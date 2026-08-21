# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the admin user
user = User.find_or_initialize_by(email: "admin@admin.com")
user.name = "Admin User"
user.avatar_url = "https://i.pravatar.cc/160?u=admin@admin.com"
if user.new_record?
  user.password = "Password"
  user.password_confirmation = "Password"
end
user.save!

quinn = User.find_or_initialize_by(email: "quinn@admin.com")
quinn.name = "Quinn Owner"
quinn.avatar_url = nil
if quinn.new_record?
  quinn.password = "Password"
  quinn.password_confirmation = "Password"
end
quinn.save!

viewer = User.find_or_initialize_by(email: "view@admin.com")
viewer.name = "View Only"
viewer.avatar_url = "https://i.pravatar.cc/160?u=view@admin.com"
if viewer.new_record?
  viewer.password = "Password"
  viewer.password_confirmation = "Password"
end
viewer.save!

# Create the workspace recordable
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")

# Create the root recording
root_recording = RecordingStudio.root_recording_for(workspace)

grant_access_result = lambda do |recording:, actor:, role:, manager_actor:|
  access_root = RecordingStudio.root_recording_or_self(recording)

  RecordingStudioAccessible::AccessCreationContext.allow do
    existing_recording = RecordingStudio::Recording.unscoped
      .where(
        root_recording_id: access_root.id,
        parent_recording_id: recording.id,
        recordable_type: "RecordingStudio::Access"
      )
      .includes(:recordable)
      .detect { |access_recording| access_recording.recordable&.actor == actor }

    if existing_recording
      access = existing_recording.recordable
      return existing_recording if access&.actor == actor && access.role == role.to_s

      access_root.revise(existing_recording, actor: manager_actor) do |updated_access|
        updated_access.actor = actor
        updated_access.role = role
      end
    else
      access_root.record(RecordingStudio::Access, actor: manager_actor, parent_recording: recording) do |access|
        access.actor = actor
        access.role = role
      end
    end
  end
end

# Grant root-level admin access to the admin user
Current.actor = user
grant_access_result.call(recording: root_recording, actor: user, role: :admin, manager_actor: user)
grant_access_result.call(recording: root_recording, actor: quinn, role: :edit, manager_actor: user)

# Create a sample folder (not commentable)
folder = Folder.find_or_create_by!(name: "Reference Folder")

# Create scenario pages
quinn_page = Page.find_or_create_by!(title: "Quinn owns this document")
Page.where(id: quinn_page.id).update_all(
  body: "Only Quinn should be able to comment on this page. Admin User should be denied by explicit page access."
)
quinn_page.reload

admin_page = Page.find_or_create_by!(title: "Admin User owns this document")
Page.where(id: admin_page.id).update_all(
  body: "Only Admin User should be able to comment on this page. Other seeded users should be denied by explicit page access."
)
admin_page.reload

Page.where(title: "Publicly accessible document").update_all(title: "Quinn and Admin User can comment")

public_page = Page.find_or_create_by!(title: "Quinn and Admin User can comment")
Page.where(id: public_page.id).update_all(
  body: "Admin User and Quinn can comment on this page. View Only can open the feed, but cannot add comments because this page grants view access only."
)
public_page.reload

scenario_recordables = [folder, quinn_page, admin_page, public_page]

scenario_root_recordings = RecordingStudio::Recording.unscoped
  .where(recordable: scenario_recordables)

recording_ids_to_remove = scenario_root_recordings.pluck(:id)
pending_ids = recording_ids_to_remove.dup

while pending_ids.any?
  child_ids = RecordingStudio::Recording.unscoped.where(parent_recording_id: pending_ids).pluck(:id)
  child_ids -= recording_ids_to_remove
  break if child_ids.empty?

  recording_ids_to_remove.concat(child_ids)
  pending_ids = child_ids
end

if recording_ids_to_remove.any?
  scoped_recordings = RecordingStudio::Recording.unscoped.where(id: recording_ids_to_remove)
  comment_recordings = scoped_recordings.where(recordable_type: "RecordingStudioCommentable::Comment")
  access_recordings = scoped_recordings.where(recordable_type: "RecordingStudio::Access")

  RecordingStudio::Event.where(recording_id: recording_ids_to_remove).delete_all
  RecordingStudioCommentable::Comment.where(id: comment_recordings.select(:recordable_id)).delete_all
  RecordingStudio::Access.where(id: access_recordings.select(:recordable_id)).delete_all if defined?(RecordingStudio::Access)
  if defined?(RecordingStudio::AccessBoundary)
    RecordingStudio::AccessBoundary.where(
      id: scoped_recordings.where(recordable_type: "RecordingStudio::AccessBoundary").select(:recordable_id)
    ).delete_all
  end
  scoped_recordings.delete_all
end

folder_recording = RecordingStudio.root_recording_for(folder)
quinn_page_recording = RecordingStudio.root_recording_for(quinn_page)
admin_page_recording = RecordingStudio.root_recording_for(admin_page)
public_page_recording = RecordingStudio.root_recording_for(public_page)

{
  folder_recording => [[user, :edit], [quinn, :edit]],
  quinn_page_recording => [[quinn, :edit]],
  admin_page_recording => [[user, :edit]],
  public_page_recording => [[user, :edit], [quinn, :edit], [viewer, :view]]
}.each do |recording, grants|
  grants.each do |actor, role|
    grant_access_result.call(recording: recording, actor: actor, role: role, manager_actor: user)
  end
end

create_seed_comment = lambda do |parent_recording:, body:, author:|
  Current.actor = author

  result = RecordingStudioCommentable::Services::CreateComment.call(
    parent_recording: parent_recording,
    body: body,
    author: author
  )

  raise "Failed to seed comment: #{Array(result.errors).join(", ")}" unless result.success?

  RecordingStudio::Recording.unscoped
    .where(parent_recording_id: parent_recording.id, recordable: result.value)
    .order(created_at: :desc)
    .first!
end

public_intro_comment_recording = create_seed_comment.call(
  parent_recording: public_page_recording,
  author: user,
  body: "Welcome to the shared thread. Use this page to verify the default comments feed with seeded content."
)

create_seed_comment.call(
  parent_recording: public_intro_comment_recording,
  author: quinn,
  body: "Reply sample: Quinn can respond here, which makes the feed show a threaded conversation immediately."
)

create_seed_comment.call(
  parent_recording: public_page_recording,
  author: quinn,
  body: "A second top-level comment gives the paginated feed examples enough items to demonstrate the different loading modes."
)

create_seed_comment.call(
  parent_recording: quinn_page_recording,
  author: quinn,
  body: "Quinn-owned page sample comment. This should only be writable for Quinn in the dummy scenarios."
)

create_seed_comment.call(
  parent_recording: admin_page_recording,
  author: user,
  body: "Admin-owned page sample comment. This gives the dedicated scenario page a visible thread from the first load."
)

Current.actor = user

puts "Seeded: admin@admin.com / Password"
puts "Seeded: quinn@admin.com / Password"
puts "Seeded: view@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Folder '#{folder.name}' recording ##{folder_recording.id}"
puts "Seeded: Page '#{quinn_page.title}' recording ##{quinn_page_recording.id}"
puts "Seeded: Page '#{admin_page.title}' recording ##{admin_page_recording.id}"
puts "Seeded: Page '#{public_page.title}' recording ##{public_page_recording.id}"
puts "Seeded: Sample comments for the scenario pages"
