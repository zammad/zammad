# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    class SystemReport
      class Plugins < Tasks::Zammad::Command

        def self.description
          'Lists the available system report plugins.'
        end

        def self.task_handler
          puts ::SystemReport.plugins.to_json
        end
      end
    end
  end
end
