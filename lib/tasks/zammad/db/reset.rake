namespace :zammad do

  namespace :db do

    desc 'Drops, recreates and seeds the database, clears the Cache and reloads the Settings'
    task reset: :environment do

      # we loop over each dependent task to be able to
      # execute them and their prerequisites multiple times (in tests)
      # there is no way in rake to achive that
      %w[db:drop:_unsafe db:create db:schema:load db:seed].each do |task|

        $stdout = StringIO.new if task == 'db:schema:load'.freeze

        Rake::Task[task].reenable
        Rake::Task[task].invoke
      ensure
        $stdout = STDOUT

      end

      ActiveRecord::Base.connection.reconnect!
      Cache.clear
      Setting.reload
    end
  end
end
