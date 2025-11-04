# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :db do

    desc 'Truncates and seeds the database, clears the cache and reloads the settings'
    task reset: :environment do

      # we loop over each dependent task to be able to
      # execute them and their prerequisites multiple times (in tests)
      # there is no way in rake to achieve that
      %w[zammad:db:truncate db:migrate db:seed zammad:db:rebuild].each do |task|
        case task
        when 'db:migrate'

          # make sure that old column schemas are getting dropped to prevent
          # wrong schema for new db setup
          ActiveRecord::Base.descendants.each(&:reset_column_information)

          $stdout = StringIO.new
        end

        Rake::Task[task].reenable
        Rake::Task[task].invoke
      ensure
        $stdout = STDOUT
      end
    end
  end
end
