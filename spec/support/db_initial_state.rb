# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.before :suite do
    if !ENV['CI_SKIP_DB_RESET']

      # DATABASE_URL replaces the database of every environment, the test one included.
      database = ActiveRecord::Base.connection_db_config.database
      abort "The test suite resets its database, but '#{database}' does not have 'test' in its name. Check DATABASE_URL and config/database.yml." if database.exclude?('test')

      # Reset database to be ready for tests
      Rake::Task['zammad:db:reset'].execute

      # make sure that all migrations of linked packages are executed
      Package::Migration.linked
    end
  end
end
