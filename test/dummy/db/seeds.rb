# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

PASSWORD = "Password" unless defined?(PASSWORD)

def upsert_user(email:, name:, avatar_url:)
  user = User.find_or_initialize_by(email: email)
  user.name = name
  user.avatar_url = avatar_url
  if user.new_record?
    user.password = PASSWORD
    user.password_confirmation = PASSWORD
  end
  user.save!
  user
end

def ensure_bootstrap_owner!(actor:, recording:)
  result = RecordingStudioAccessible.bootstrap_owner_access!(
    recording: recording,
    actor: actor
  )
  raise result.error if result.failure?

  result.value
end

def ensure_access_grant!(recording:, actor:, role:, manager_actor:)
  result = RecordingStudioAccessible.grant_access(
    recording: recording,
    actor: actor,
    role: role,
    manager_actor: manager_actor
  )
  raise result.error if result.failure?

  result.value
end

def purge_recordings!(recordables)
  scenario_root_recordings = RecordingStudio::Recording.unscoped.where(recordable: recordables)
  recording_ids_to_remove = scenario_root_recordings.pluck(:id)
  pending_ids = recording_ids_to_remove.dup

  while pending_ids.any?
    child_ids = RecordingStudio::Recording.unscoped.where(parent_recording_id: pending_ids).pluck(:id)
    child_ids -= recording_ids_to_remove
    break if child_ids.empty?

    recording_ids_to_remove.concat(child_ids)
    pending_ids = child_ids
  end

  return if recording_ids_to_remove.empty?

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

def create_seed_comment(parent_recording:, body:, author:)
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

user = upsert_user(email: "admin@admin.com", name: "Admin User", avatar_url: "https://i.pravatar.cc/160?u=admin@admin.com")
quinn = upsert_user(email: "quinn@admin.com", name: "Quinn Owner", avatar_url: nil)
viewer = upsert_user(email: "view@admin.com", name: "View Only", avatar_url: "https://i.pravatar.cc/160?u=view@admin.com")

workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
root_recording = RecordingStudio.root_recording_for(workspace)

Current.actor = user
ensure_bootstrap_owner!(actor: user, recording: root_recording)
ensure_access_grant!(recording: root_recording, actor: quinn, role: :edit, manager_actor: user)

folder = Folder.find_or_create_by!(name: "Reference Folder")

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

purge_recordings!([folder, quinn_page, admin_page, public_page])

folder_recording = RecordingStudio.root_recording_for(folder)
quinn_page_recording = RecordingStudio.root_recording_for(quinn_page)
admin_page_recording = RecordingStudio.root_recording_for(admin_page)
public_page_recording = RecordingStudio.root_recording_for(public_page)

ensure_bootstrap_owner!(actor: user, recording: folder_recording)
ensure_access_grant!(recording: folder_recording, actor: quinn, role: :edit, manager_actor: user)

ensure_bootstrap_owner!(actor: quinn, recording: quinn_page_recording)
ensure_bootstrap_owner!(actor: user, recording: admin_page_recording)

ensure_bootstrap_owner!(actor: user, recording: public_page_recording)
ensure_access_grant!(recording: public_page_recording, actor: quinn, role: :edit, manager_actor: user)
ensure_access_grant!(recording: public_page_recording, actor: viewer, role: :view, manager_actor: user)

public_intro_comment_recording = create_seed_comment(
  parent_recording: public_page_recording,
  author: user,
  body: "Welcome to the shared thread. Use this page to verify the default comments feed with seeded content."
)

create_seed_comment(
  parent_recording: public_intro_comment_recording,
  author: quinn,
  body: "Reply sample: Quinn can respond here, which makes the feed show a threaded conversation immediately."
)

create_seed_comment(
  parent_recording: public_page_recording,
  author: quinn,
  body: "A second top-level comment gives the paginated feed examples enough items to demonstrate the different loading modes."
)

create_seed_comment(
  parent_recording: quinn_page_recording,
  author: quinn,
  body: "Quinn-owned page sample comment. This should only be writable for Quinn in the dummy scenarios."
)

create_seed_comment(
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
