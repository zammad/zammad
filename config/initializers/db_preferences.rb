# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

case ActiveRecord::Base.connection_config[:adapter]
when 'mysql2'
  Rails.application.config.db_4bytes_utf8 = false
  Rails.application.config.db_case_sensitive = false
  Rails.application.config.db_like = 'LIKE'
  Rails.application.config.db_null_byte = true

  # Because of missing ticket updates in high load environments
  # we changed the transaction isolation level equally to postgres
  # to READ COMMITTED which fixed the problem entirely #3877
  ActiveRecord::ConnectionAdapters::Mysql2Adapter.set_callback :checkout, :before do |conn|
    conn.execute('SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED')
  end
when 'postgresql'
  Rails.application.config.db_4bytes_utf8 = true
  Rails.application.config.db_case_sensitive = true
  Rails.application.config.db_like = 'ILIKE'
  Rails.application.config.db_null_byte = false
end
