# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :db do

    desc 'Drops, recreates and seeds the database, clears the Cache and reloads the Settings'
    task reset: :environment do

      # we loop over each dependent task to be able to
      # execute them and their prerequisites multiple times (in tests)
      # there is no way in rake to achieve that
      %w[db:drop:_unsafe db:create db:migrate db:seed].each do |task|

        $stdout = StringIO.new if task == 'db:migrate'.freeze

        Rake::Task[task].reenable
        Rake::Task[task].invoke
      ensure
        $stdout = STDOUT
      end

      Package::Migration.linked
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.descendants.each(&:reset_column_information)
      Cache.clear
      Setting.reload
    end
  end
end
