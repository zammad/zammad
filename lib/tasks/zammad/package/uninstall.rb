# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class Uninstall < Tasks::Zammad::Command

        def self.usage
          "#{super} MyPackage"
        end

        def self.description
          'Uninstall a Zammad addon package'
        end

        ARGUMENT_COUNT = 1

        def self.task_handler
          name = ArgvHelper.argv[1]
          if name.blank?
            abort "Error: please provide a package name: #{ArgvHelper.argv[0]} MyPackage"
          end
          # Find the package so that we don't need to require the version from the command line.
          package = ::Package.find_by(name: name)
          if package.blank?
            abort "Error: package #{name} was not found."
          end
          puts "Uninstalling #{package.name} #{package.version}..."
          ::Package.uninstall(name: package.name, version: package.version)
          puts 'done.'
        end

      end
    end
  end
end
