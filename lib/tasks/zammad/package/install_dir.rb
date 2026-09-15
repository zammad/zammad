# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'tasks/zammad/package_command'

module Tasks
  module Zammad
    module Package
      class InstallDir < Tasks::Zammad::PackageCommand

        def self.usage
          "#{super} /path/to/directory"
        end

        def self.description
          'Install or update all Zammad addon packages from a directory in dependency order'
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

          puts "Installing all packages in #{directory} (without package migrations)..."
          ::Package.install_dir(directory, write_files: !::Zammad::Deployment.container?)
          puts 'done.'
          puts "Please run package migrations now via 'zammad:package:migrate'."
        end

      end
    end
  end
end
