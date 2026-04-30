# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the admin user
user = User.find_or_create_by!(email: "admin@admin.com") do |u|
  u.password = "Password"
  u.password_confirmation = "Password"
end

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

# Create a sample folder (not commentable)
folder = Folder.find_or_create_by!(name: "Project Folder")
folder_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: root_recording.id,
  recordable: folder
)

# Create a sample page (commentable)
page = Page.find_or_create_by!(title: "Getting Started") do |p|
  p.body = "Welcome to the project. Leave your comments below."
end
page_recording = RecordingStudio::Recording.unscoped.find_or_create_by!(
  root_recording_id: root_recording.id,
  parent_recording_id: folder_recording.id,
  recordable: page
)

puts "Seeded: admin@admin.com / Password"
puts "Seeded: Workspace '#{workspace.name}' with root recording ##{root_recording.id}"
puts "Seeded: Folder '#{folder.name}' recording ##{folder_recording.id}"
puts "Seeded: Page '#{page.title}' recording ##{page_recording.id} (commentable)"
