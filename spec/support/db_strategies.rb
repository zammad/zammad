# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  config.filter_run_excluding db_adapter: lambda { |adapter|
    adapter_config = ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
    case adapter
    when :postgresql
      adapter_config != 'postgresql'
    when :mysql
      adapter_config != 'mysql2'
    else
      false
    end
  }
end
