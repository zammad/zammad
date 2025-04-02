# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module EmailParser
      module FailedEmail
        class DeleteOld < Tasks::Zammad::Command

          def self.description
            'Removes all failed emails older than 24 hours'
          end

          ARGUMENT_COUNT = 0

          def self.task_handler
            puts 'Deleting failed emails older than 24 hours.'

            destroyed = ::FailedEmail
              .where(updated_at: ...24.hours.ago)
              .destroy_all

            puts "#{destroyed.count} email(s) deleted."
            puts 'Done.'
          end
        end
      end
    end
  end
end
