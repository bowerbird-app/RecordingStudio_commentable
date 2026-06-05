# frozen_string_literal: true

# Folder is a recordable that does NOT support comments.
# It demonstrates the negative case — visiting a folder's comment feed
# redirects away with an error.
class Folder < ApplicationRecord
	recording_studio_recordable(
		label: "Folder",
		plural_label: "Folders",
		root: true
	)

	RecordingStudio.enable_capability(:accessible, on: self) if defined?(RecordingStudioAccessible)
end
