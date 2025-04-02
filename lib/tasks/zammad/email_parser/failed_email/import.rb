# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require_dependency 'tasks/zammad/email_parser/failed_email/base.rb'

module Tasks
  module Zammad
    module EmailParser
      module FailedEmail
        class Import < Base

          def self.usage
            <<~USAGE
              Usage: bundle exec rails #{task_name} /folder_with_downloaded_emails  # Imports all found .eml files
                 or: bundle exec rails #{task_name} /folder_with_downloaded_emails/single_file.eml
            USAGE
          end

          def self.description
            'Import and reprocess locally modified failed email files. Files will be deleted on success.'
          end

          def self.task_handler
            process_given_dir_or_file
          end

          def self.process_dir(path)
            imported = ::FailedEmail.import_all(path)

            if imported.blank?
              puts 'No email files could be imported and reprocessed successfully.'
              return
            end

            puts "#{imported.count} file(s) imported and successfully reprocessed:"
            imported.each { |f| puts "  #{f}" }
          end

          def self.process_file(path)
            if !path.exist? || path.extname != '.eml'
              raise "#{path} is not a valid .eml file."
            end

            if ::FailedEmail.import(path)
              puts "#{path} was imported and successfully reprocessed."
            else
              puts "#{path} was not imported and reprocessed successfully."
            end
          end
        end
      end
    end
  end
end
