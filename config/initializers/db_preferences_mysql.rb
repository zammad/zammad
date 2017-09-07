# mysql
if ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
  Rails.application.config.db_4bytes_utf8 = false
  Rails.application.config.db_null_byte = true

  # mysql version check
  #  mysql example: "5.7.3"
  #  mariadb example: "10.1.17-MariaDB"
  server_version = ActiveRecord::Base.connection.select_rows('SHOW VARIABLES LIKE \'version\'')[0][1]
  raise 'Unable to retrive database version' if !server_version
  (server_version, server_vendor) = server_version.split('-')
  if !server_vendor
    server_vendor = 'MySQL'
  end
  (major, minor) = server_version.split('.')
  if server_vendor == 'MySQL'
    if major.to_i < 5 || (major.to_i == 5 && minor.to_i < 6)
      # rubocop:disable Rails/Output
      # rubocop:disable Rails/Exit
      p '+++++++++++++++++++++++++++++++++++++++++++++++++++++'
      p '+ I\'m sorry, MySQL 5.6+ is required                 +'
      p '+++++++++++++++++++++++++++++++++++++++++++++++++++++'
      exit 1
      # rubocop:enable Rails/Exit
      # rubocop:enable Rails/Output
    end

  elsif server_vendor == 'MariaDB'
    if major.to_i < 10
      # rubocop:disable Rails/Output
      # rubocop:disable Rails/Exit
      p '+++++++++++++++++++++++++++++++++++++++++++++++++++++'
      p '+ I\'m sorry, MariaDB 10.0+ is required              +'
      p '+++++++++++++++++++++++++++++++++++++++++++++++++++++'
      exit 1
      # rubocop:enable Rails/Exit
      # rubocop:enable Rails/Output
    end
  end
end
