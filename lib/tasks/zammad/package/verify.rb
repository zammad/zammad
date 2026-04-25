# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      class Verify < Tasks::Zammad::Command

        def self.description
          'Verfies all installed Zammad addon packages'
        end

        def self.task_handler
          puts 'Name'.ljust(50) + 'Status'.ljust(20)
          ::Package.all.sort_by(&:name).each do |package|
            verify = package.verify
            status = verify.nil? ? 'OK' : "FAILED (#{verify.keys.count} issues)"

            puts package.name.ljust(50) + status.ljust(20)
          end
        end

      end
    end
  end
end
