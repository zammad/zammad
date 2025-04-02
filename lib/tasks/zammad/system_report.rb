# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    class SystemReport < Tasks::Zammad::Command

      def self.description
        'Fetches the system report.'
      end

      def self.task_handler
        puts ::SystemReport.fetch.to_json
      end
    end
  end
end
