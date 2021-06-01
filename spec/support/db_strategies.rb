# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|

  config.around(:each, db_strategy: :reset) do |example|
    if ActiveRecord::Base.connection.instance_values['config'][:adapter] != 'postgresql'
      self.use_transactional_tests = false
    end
    example.run
    if ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'
      Models.all.each_key do |model|
        model.connection.schema_cache.clear!
        model.reset_column_information
      end
    else
      Rake::Task['zammad:db:reset'].reenable
      Rake::Task['zammad:db:reset'].invoke
    end
  end
end
