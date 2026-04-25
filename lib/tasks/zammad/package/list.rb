# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class List < Tasks::Zammad::Command

        def self.description
          'List all installed Zammad addon packages'
        end

        def self.task_handler
          puts "#{'Name'.ljust(50)}#{'Vendor'.ljust(20)}Version"
          ::Package.all.sort_by(&:name).each do |package|
            puts package.name.ljust(50) + package.vendor.ljust(20) + package.version
          end
        end

      end
    end
  end
end
