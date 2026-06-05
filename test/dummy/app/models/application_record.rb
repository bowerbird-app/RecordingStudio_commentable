require "recording_studio"

# In development reload cycles, ensure the recordable declaration macro is
# present before model classes call recording_studio_recordable(...).
RecordingStudio::RecordableDeclarations.install_active_record_macro! if defined?(RecordingStudio::RecordableDeclarations)

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
