# set database preferences

# defaults
Rails.application.config.db_case_sensitive = false
Rails.application.config.db_like = 'LIKE'
Rails.application.config.db_4bytes_utf8 = true

# postgresql
if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
  Rails.application.config.db_case_sensitive = true
  Rails.application.config.db_like = 'ILIKE'
end

# mysql
if ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
  Rails.application.config.db_4bytes_utf8 = false
end
