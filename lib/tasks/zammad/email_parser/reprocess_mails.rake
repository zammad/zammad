# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :email_parser do

    desc 'Reprocess mails which failed to parse and were saved as unprocessable.'
    task reprocess_mails: :environment do |_task, _args|
      Channel::EmailParser.process_unprocessable_mails
      puts 'done.'
    end
  end
end
