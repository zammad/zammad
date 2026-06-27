# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'tasks/zammad/command'

module Tasks
  module Zammad
    module DataPrivacy
      module Failed
        class Retry < Tasks::Zammad::Command
          def self.description
            'Restarts all failed data privacy task jobs'
          end

          def self.task_handler
            puts 'Restarting failed data privacy task jobs...'

            DataPrivacyTask.failed.find_each do |task|
              task.prepare_deletion_preview
              task.state = 'in process'
              task.save!

              puts "#{task.deletable.class} #{task.deletable_id} (#{task.deletion_counts.inspect})"
            end

            puts 'done.'
          end

        end
      end
    end
  end
end
