# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Package
      # Package migrations must not be executed in the same process that also executed
      #   Package.install or Package.link, as the codebase is in an inconsistent state.
      # This is enforced by Tasks:Zammad::Command which prevents command chaining.
      class Migrate < Tasks::Zammad::Command

        def self.task_handler
          puts 'Executing all pending package migrations...'
          ::Package.migration_execute
          ::Package::Migration.linked
          puts 'done.'
        end

      end
    end
  end
end
