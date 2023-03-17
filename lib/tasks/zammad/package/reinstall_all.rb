# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class ReinstallAll < Tasks::Zammad::Command

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
