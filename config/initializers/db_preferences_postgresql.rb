# postgresql
if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
  Rails.application.config.db_case_sensitive = true
  Rails.application.config.db_like = 'ILIKE'
  Rails.application.config.db_null_byte = false

  # postgresql version check
  #  example output: "9.5.0"
  server_version = ActiveRecord::Base.connection.select_rows('SHOW server_version;')[0][0]
  (major, minor) = server_version.split('.')
  if major.to_i < 9 || (major.to_i == 9 && minor.to_i < 1)

    # rubocop:disable Rails/Output
    # rubocop:disable Rails/Exit
    p '+++++++++++++++++++++++++++++++++++++++++++++++++++++'
    p '+ I\'m sorry, PostgreSQL 9.1+ is required            +'
    p '+++++++++++++++++++++++++++++++++++++++++++++++++++++'
    exit 1
    # rubocop:enable Rails/Exit
    # rubocop:enable Rails/Output

  end
end
