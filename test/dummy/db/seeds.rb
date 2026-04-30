# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the admin user
user = User.find_or_initialize_by(email: "admin@admin.com")
user.name = "Admin User"
if user.new_record?
  user.password = "Password"
  user.password_confirmation = "Password"
end
user.save!

quinn = User.find_or_initialize_by(email: "quinn@admin.com")
quinn.name = "Quinn Owner"
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
folder_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: folder
)

# Create scenario pages
quinn_page = Page.find_or_create_by!(title: "Quinn owns this document") do |p|
  p.body = "Only Quinn should be able to comment on this page. Admin User should be denied by the access boundary."
end
quinn_page_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: folder_recording.id,
  recordable: quinn_page
)

admin_page = Page.find_or_create_by!(title: "Admin User owns this document") do |p|
  p.body = "Only Admin User should be able to comment on this page. Other seeded users should be denied."
end
admin_page_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: folder_recording.id,
  recordable: admin_page
)

public_page = Page.find_or_create_by!(title: "Publicly accessible document") do |p|
  p.body = "Both seeded users inherit enough access to comment on this page in the demo."
end
public_page_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: folder_recording.id,
  recordable: public_page
)

scenario_recordings = [quinn_page_recording, admin_page_recording, public_page_recording]

scenario_recordings.each do |recording|
  comment_recordings = RecordingStudio::Recording.unscoped
    .where(parent_recording_id: recording.id, recordable_type: "RecordingStudioCommentable::Comment")

  RecordingStudio::Event.where(recording_id: comment_recordings.select(:id)).delete_all
  RecordingStudioCommentable::Comment.where(id: comment_recordings.select(:recordable_id)).delete_all
  comment_recordings.delete_all

  access_recordings = RecordingStudio::Recording.unscoped
    .where(parent_recording_id: recording.id, recordable_type: "RecordingStudio::Access")

  RecordingStudio::Event.where(recording_id: access_recordings.select(:id)).delete_all
  access_recordings.delete_all

  boundary_recordings = RecordingStudio::Recording.unscoped
    .where(parent_recording_id: recording.id, recordable_type: "RecordingStudio::AccessBoundary")

  RecordingStudio::Event.where(recording_id: boundary_recordings.select(:id)).delete_all
  RecordingStudio::AccessBoundary.where(id: boundary_recordings.select(:recordable_id)).delete_all
  boundary_recordings.delete_all
end

[
  [quinn_page_recording, quinn],
  [admin_page_recording, user]
].each do |recording, owner|
  boundary_recording = RecordingStudio::Recording.unscoped
    .where(parent_recording_id: recording.id, recordable_type: "RecordingStudio::AccessBoundary", trashed_at: nil)
    .order(created_at: :desc)
    .first

  unless boundary_recording
    boundary = RecordingStudio::AccessBoundary.create!
    RecordingStudio::Recording.unscoped.create!(
      root_recording_id: root_recording.id,
      parent_recording_id: recording.id,
      recordable: boundary
    )
  end

  owner_access = RecordingStudio::Access.find_or_create_by!(actor: owner, role: :edit)
  RecordingStudio::Recording.unscoped.find_or_create_by!(
    root_recording_id: root_recording.id,
    parent_recording_id: recording.id,
    recordable: owner_access
  )
end

puts "Seeded: admin@admin.com / Password"
puts "Seeded: quinn@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Folder '#{folder.name}' recording ##{folder_recording.id}"
puts "Seeded: Page '#{quinn_page.title}' recording ##{quinn_page_recording.id}"
puts "Seeded: Page '#{admin_page.title}' recording ##{admin_page_recording.id}"
puts "Seeded: Page '#{public_page.title}' recording ##{public_page_recording.id}"
