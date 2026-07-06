# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'tasks/zammad/package_command'

module Tasks
  module Zammad
    module Package
      class ReinstallAll < Tasks::Zammad::PackageCommand

        def self.description
          'Reinstall all installed Zammad addon packages'
        end

        def self.task_handler
          puts 'Reinstalling all packages...'
          ::Package.find_each do |package|
            puts "Reinstalling '#{package.name}' (#{package.version})..."
            ::Package.reinstall(package.name)
          end
          puts 'done.'
        end
      end
    end
  end
end
