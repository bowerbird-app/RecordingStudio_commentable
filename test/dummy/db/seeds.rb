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

# Create the workspace recordable
workspace = Workspace.find_or_create_by!(name: "Studio Workspace")

# Create the root recording
root_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  recordable: workspace,
  parent_recording_id: nil
)

# Grant root-level admin access to the admin user
Current.actor = user
access = RecordingStudio::Access.find_or_create_by!(actor: user, role: :admin)
RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: access
)

quinn_root_access = RecordingStudio::Access.find_or_create_by!(actor: quinn, role: :edit)
RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: quinn_root_access
)

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
  body: "Both seeded users can comment on this page because it grants explicit access to each of them."
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

  RecordingStudio::Event.where(recording_id: recording_ids_to_remove).delete_all
  RecordingStudioCommentable::Comment.where(id: comment_recordings.select(:recordable_id)).delete_all
  RecordingStudio::AccessBoundary.where(
    id: scoped_recordings.where(recordable_type: "RecordingStudio::AccessBoundary").select(:recordable_id)
  ).delete_all
  scoped_recordings.delete_all
end

folder_recording = RecordingStudio::Recording.unscoped.create!(
  parent_recording_id: nil,
  recordable: folder
)

quinn_page_recording = RecordingStudio::Recording.unscoped.create!(
  parent_recording_id: nil,
  recordable: quinn_page
)

admin_page_recording = RecordingStudio::Recording.unscoped.create!(
  parent_recording_id: nil,
  recordable: admin_page
)

public_page_recording = RecordingStudio::Recording.unscoped.create!(
  parent_recording_id: nil,
  recordable: public_page
)

{
  folder_recording => [[user, :edit], [quinn, :edit]],
  quinn_page_recording => [[quinn, :edit]],
  admin_page_recording => [[user, :edit]],
  public_page_recording => [[user, :edit], [quinn, :edit]]
}.each do |recording, grants|
  grants.each do |actor, role|
    access_record = RecordingStudio::Access.find_or_create_by!(actor: actor, role: role)
    RecordingStudio::Recording.unscoped.create!(
      root_recording_id: recording.id,
      parent_recording_id: recording.id,
      recordable: access_record
    )
  end
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: quinn@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Folder '#{folder.name}' recording ##{folder_recording.id}"
puts "Seeded: Page '#{quinn_page.title}' recording ##{quinn_page_recording.id}"
puts "Seeded: Page '#{admin_page.title}' recording ##{admin_page_recording.id}"
puts "Seeded: Page '#{public_page.title}' recording ##{public_page_recording.id}"
