# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module EmailParser
      module FailedEmail
        class Base < Tasks::Zammad::Command
          ARGUMENT_COUNT = 1

          def self.process_given_dir_or_file
            file_or_folder = resolve_filepath(ArgvHelper.argv[1])

            if file_or_folder.directory?
              process_dir(file_or_folder)

              delete_empty_enclosing_dir(file_or_folder)
            elsif file_or_folder.file?
              process_file(file_or_folder)

              delete_empty_enclosing_dir(file_or_folder.parent)
            else
              puts 'Given path does not exist.'
            end

            puts 'Done.'
          end

          def self.process_dir; end
          def self.process_file; end

          def self.delete_empty_enclosing_dir(path)
            return if !path.empty?

            puts "Deleting directory #{path}."
            path.rmdir
          rescue => e
            puts "Could not delete #{path}."
            puts e.inspect
          end
        end
      end
    end
  end
end
