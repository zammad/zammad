# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module DataPrivacy
      module Failed
        class Show < Tasks::Zammad::Command
          def self.description
            'Shows all failed data privacy task jobs'
          end

          def self.task_handler
            puts 'Data privacy task jobs in failed state...'

            DataPrivacyTask.failed.find_each do |task|
              puts "#{task.deletable.class} #{task.deletable_id} (#{task.deletion_counts.inspect})"
            end

            puts 'done.'
          end

        end
      end
    end
  end
end
