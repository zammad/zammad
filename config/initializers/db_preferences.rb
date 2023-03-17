# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

case ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
when 'mysql2'
  Rails.application.config.db_4bytes_utf8 = false
  Rails.application.config.db_column_array = false
  Rails.application.config.db_case_sensitive = false
  Rails.application.config.db_like = 'LIKE'
  Rails.application.config.db_null_byte = true

  # Because of missing ticket updates in high load environments
  # we changed the transaction isolation level equally to postgres
  # to READ COMMITTED which fixed the problem entirely #3877
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.set_callback :checkout, :after do |conn|
    conn.execute('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED')
  end
when 'postgresql'
  Rails.application.config.db_4bytes_utf8 = true
  Rails.application.config.db_column_array = true
  Rails.application.config.db_case_sensitive = true
  Rails.application.config.db_like = 'ILIKE'
  Rails.application.config.db_null_byte = false
end
