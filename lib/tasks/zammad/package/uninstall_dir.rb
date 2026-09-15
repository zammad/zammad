# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'tasks/zammad/package_command'

module Tasks
  module Zammad
    module Package
      class UninstallDir < Tasks::Zammad::PackageCommand

        def self.usage
          "#{super} /path/to/directory"
        end

        def self.description
          'Uninstall all Zammad addon packages from a directory in reverse dependency order'
        end

        ARGUMENT_COUNT = 1

        def self.task_handler
          directory = ArgvHelper.argv[1]
          if directory.blank?
            abort "Error: Please provide a valid directory: #{usage}"
          end
          if !File.directory?(directory)
            abort "Could not find directory #{directory}."
          end

          puts "Uninstalling all packages in #{directory} (including package migrations)..."
          ::Package.uninstall_dir(directory, remove_files: !::Zammad::Deployment.container?)
          puts 'done.'
        end

      end
    end
  end
end
