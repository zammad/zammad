# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do
  namespace :email_parser do
    namespace :debug do

      desc 'Regenerate all sample mails'
      task regenerate_all_ymls: :environment do |_task, _args|
        Dir.glob('test/data/mail/mail*.box').each do |mail_file|
          target_yml_file = mail_file.gsub('.box', '.yml')

          parsed = Channel::EmailParser.prepare_sample_mail(File.read(mail_file))
          File.write(target_yml_file, parsed.to_yaml)
        end
      end
    end
  end
end
