# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do
  namespace :email_parser do
    namespace :failed_article do

      desc 'Reprocess articles which failed to parse.'
      task reprocess_all: :environment do |_task, _args|
        Channel::EmailParser.reprocess_failed_articles
        puts 'done.'
      end
    end

  end
end
