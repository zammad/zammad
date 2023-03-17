# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class Install < Tasks::Zammad::Command

        def self.usage
          "#{super} /path/to/package.zpm"
        end

        def self.description
          'Install a Zammad addon package'
        end

        ARGUMENT_COUNT = 1

        def self.task_handler
          filename = ArgvHelper.argv[1]
          if filename.blank?
            abort "Error: Please provide a valid filename: #{usage}"
          end
          if !File.exist?(filename)
            abort "Could not find file #{filename}."
          end
          puts "Installing #{filename} (without package migrations)..."
          ::Package.install(file: filename)
          puts 'done.'
          puts "Please run package migrations now via 'zammad:package:migrate'."
        end

      end
    end
  end
end
