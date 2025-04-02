# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do
  namespace :email_parser do
    namespace :failed_email do

      desc 'Export all failed emails to a local folder.'
      task export_all: :environment do |_task, _args|
        files = FailedEmail.export_all
        if files.present?
          puts "#{files.count} failed email(s) exported:"
          files.each do |f|
            puts "  #{f}"
          end
        else
          puts 'No failed emails were found.'
        end
        puts 'Done.'
      end
    end
  end
end
