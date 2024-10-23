# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Store
      class VerifyFiles < Tasks::Zammad::Command
        def self.description
          'Verify files/attachments checksums.'
        end

        def self.task_handler
          puts 'Verifying files checksums...'

          status = ::Store::File.verify

          puts 'Done.'
          return if status

          warn 'One or more files could not be verified. For further information, please check the logs.'
          exit 1 # rubocop:disable Rails/Exit
        end
      end
    end
  end
end
