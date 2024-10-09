# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::PostgreSql < SystemReport::Plugin
  DESCRIPTION = __('PostgresSQL server version').freeze

  def fetch
    return if ActiveRecord::Base.connection.adapter_name != 'PostgreSQL'

    database_name = ActiveRecord::Base.connection.current_database
    ActiveRecord::Base.connection.execute("
      SELECT version() as version,
      pg_database_size('#{ActiveRecord::Base.connection.quote_string(database_name)}') as database_size,
      pg_size_pretty(pg_database_size('#{ActiveRecord::Base.connection.quote_string(database_name)}')) as database_size_human,
      (SELECT SUM(CAST(coalesce(size, '0') AS INTEGER)) FROM stores) as attachments_size,
      (SELECT pg_size_pretty(SUM(CAST(coalesce(size, '0') AS INTEGER))) FROM stores) as attachments_size_human
    ").to_a[0]
  end
end
