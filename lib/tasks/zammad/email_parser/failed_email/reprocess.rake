# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do
  namespace :email_parser do
    namespace :failed_email do

      desc 'Reprocess mails which failed to parse.'
      task reprocess_all: :environment do |_task, _args|
        successfully_reprocessed_files = FailedEmail.reprocess_all
        if successfully_reprocessed_files.present?
          puts "#{successfully_reprocessed_files.count} email(s) successfully reprocessed:\n"
          successfully_reprocessed_files.each { |f| puts "  #{f}" }
        else
          puts 'No emails were successfully reprocessed.'
        end
        puts 'Done.'
      end

    end
  end
end
