# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/command.rb'

module Tasks
  module Zammad
    module EmailParser
      module FailedEmail
        class Delete < Tasks::Zammad::Command

          def self.usage
            "#{super} /folder_with_downloaded_emails/spam_email.eml"
          end

          def self.description
            'Remove a failed email from to the database.'
          end

          ARGUMENT_COUNT = 1

          def self.task_handler
            email_file = resolve_filepath(ArgvHelper.argv[1])
            failed_email = ::FailedEmail.by_filepath(email_file)
            raise "No database record could be found for #{email_file}.\n" if !failed_email

            failed_email.destroy
            puts "Deleting failed email record #{failed_email.id}."

            if email_file.exist?
              puts "Deleting file #{email_file}."
              email_file.unlink
            end

            puts 'Done.'
          end

          def self.target_path
            given_path = Pathname.new(ArgvHelper.argv[1])

            return given_path if given_path.absolute?

            Pathname
              .new(Rake.original_dir)
              .join(ArgvHelper.argv[1])
          end

        end
      end
    end
  end
end
