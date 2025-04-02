# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module Store
      class MoveFiles < Tasks::Zammad::Command
        ARGUMENT_COUNT = 2

        def self.description
          'Move files/attachments from one store provider to another.'
        end

        def self.handle_argv
          _, source, target = ArgvHelper.argv

          [source, target].each do |provider|
            begin
              "Store::Provider::#{provider}".constantize
            rescue NameError
              warn "Store provider '#{provider}' not found."
              exit 1 # rubocop:disable Rails/Exit
            end
          end

          [source, target]
        end

        def self.usage
          "#{super} <source> <target>"
        end

        def self.task_handler
          source, target = handle_argv

          puts "Moving files from #{source} to #{target}..."

          status = ::Store::File.move(source, target)

          puts 'Done.'
          return if status

          warn 'One or more files could not be moved. For further information, please check the logs.'
          exit 1 # rubocop:disable Rails/Exit
        end
      end
    end
  end
end
