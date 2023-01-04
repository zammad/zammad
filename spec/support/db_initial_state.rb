# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.before :suite do
    if !ENV['CI_SKIP_DB_RESET']

      # Reset database to be ready for tests
      Rake::Task['zammad:db:reset'].execute

      # make sure that all migrations of linked packages are executed
      Package::Migration.linked
    end
  end
end
