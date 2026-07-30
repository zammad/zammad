# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :db do

      desc 'Initializes the DB for CI, by restoring the dump of the current pipeline if available'
      task :init do # rubocop:disable Rails/RakeEnvironment
        next if system(Rails.root.join('.gitlab/database.rb').to_s, 'restore')

        puts 'Initializing the database from scratch instead.'
        Rake::Task['zammad:db:init'].invoke
      end
    end
  end
end
