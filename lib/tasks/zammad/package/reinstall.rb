# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class Reinstall < Tasks::Zammad::Command

        def self.usage
          "#{super} MyPackage"
        end

        def self.description
          'Reinstall an installed Zammad addon package'
        end

        ARGUMENT_COUNT = 1

        def self.task_handler
          package_name = ArgvHelper.argv[1]
          if package_name.blank?
            abort "Error: Please provide a valid package name: #{usage}"
          end

          package = ::Package.find_by(name: package_name)
          if package.blank?
            abort "Could not find package #{package_name}."
          end

          puts "Reinstalling '#{package.name}' (#{package.version})..."
          ::Package.reinstall(package.name)
          puts 'done.'
        end

      end
    end
  end
end
