# frozen_string_literal: true

require "rails/generators"

module RecordingStudioCommentable
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../db/migrate", __dir__)

      desc "Copies RecordingStudioCommentable migrations to your application"

      def copy_migrations
        Dir[File.join(self.class.source_root, "*.rb")].each do |migration_file|
          base = File.basename(migration_file)
          destination = File.join(destination_root, "db/migrate", base)
          copy_file migration_file, destination unless File.exist?(destination)
        end
      end
    end
  end
end
