# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :db do

    desc 'Drops, recreates and seeds the database, clears the Cache and reloads the Settings'
    task reset: :environment do

      # we loop over each dependent task to be able to
      # execute them and their prerequisites multiple times (in tests)
      # there is no way in rake to achieve that
      %w[db:drop:_unsafe db:create db:migrate db:seed zammad:db:rebuild].each do |task|
        case task
        when 'db:migrate'

          # make sure that old column schemas are getting dropped to prevent
          # wrong schema for new db setup
          ActiveRecord::Base.descendants.each(&:reset_column_information)

          $stdout = StringIO.new
        when 'db:drop:_unsafe'
          # ensure all DB connections are closed before dropping the DB
          # since Rails > 5.2 two connections are present (after `db:migrate`) that
          # block dropping the DB for PostgreSQL
          ActiveRecord::Base.connection_handler.connection_pools.each(&:disconnect!)
        end

        Rake::Task[task].reenable
        Rake::Task[task].invoke
      ensure
        $stdout = STDOUT
      end
    end
  end
end
