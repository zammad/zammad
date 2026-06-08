# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|

  config.around(:each, db_strategy: :reset) do |example|
    example.run
    Models.all.each_key do |model|
      model.connection.schema_cache.clear!
      model.reset_column_information
    end
  end
end
