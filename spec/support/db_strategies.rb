# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|

  config.around(:each, db_strategy: :reset) do |example|
    if MysqlStrategy.db?
      self.use_transactional_tests = false
    end
    example.run
    if MysqlStrategy.db?
      MysqlStrategy.reset
    else
      Models.all.each_key do |model|
        model.connection.schema_cache.clear!
        model.reset_column_information
      end
    end
  end
end
