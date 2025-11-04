# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :db do

    desc 'Truncates the database'
    task truncate: :environment do
      ActiveRecord::Base.connection.execute(<<~SQL) # rubocop:disable Rails/SquishedSQLHeredocs
        DROP SCHEMA PUBLIC CASCADE;
        CREATE SCHEMA PUBLIC;
      SQL
    end
  end
end
