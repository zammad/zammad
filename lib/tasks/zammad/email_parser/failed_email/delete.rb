# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/email_parser/failed_email/base.rb'

module Tasks
  module Zammad
    module EmailParser
      module FailedEmail
        class Delete < Base
          def self.task_handler
            process_given_dir_or_file
          end

          def self.usage
            <<~USAGE
              Usage: bundle exec rails #{task_name} /folder_with_downloaded_emails  # Deletes all found .eml files
                 or: bundle exec rails #{task_name} /folder_with_downloaded_emails/single_file.eml
            USAGE
          end

          def self.description
            'Remove failed emails from to the database.'
          end

          def self.process_file(file)
            failed_email = ::FailedEmail.by_filepath(file)
            raise "No database record could be found for #{file}.\n" if !failed_email

            puts "Deleting failed email record #{failed_email.id}."
            failed_email.destroy!

            return if !file.exist?

            delete_file(file)
          end

          def self.delete_file(file)
            puts "Deleting file #{file}."
            file.unlink
          rescue => e
            puts "Could not delete #{file}."
            puts e.inspect
          end

          def self.process_dir(path)
            path.each_child do |filename|
              next if filename.extname != '.eml'

              process_file path.join(filename)
            end
          end
        end
      end
    end
  end
end
