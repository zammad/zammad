return if ActiveRecord::Base.connection_config[:adapter] != 'postgresql'

Rails.application.config.db_case_sensitive = true
Rails.application.config.db_like = 'ILIKE'
Rails.application.config.db_null_byte = false

# rubocop:disable Rails/Output
# rubocop:disable Rails/Exit
# rubocop:disable Layout/IndentHeredoc

# Version check --------------------------------------------------------------
#  example output: "9.5.0"
#                  "10.3 (Debian 10.3-2)"
server_version = ActiveRecord::Base.connection.execute('SHOW server_version;').first['server_version']
version_number = Gem::Version.new(server_version.split.first)

if version_number < Gem::Version.new('9.1')
  printf "\e[31m" # ANSI red
  puts <<~MSG
  Error: Incompatible database backend version
  (PostgreSQL 9.1+ required; #{version_number} found)
  MSG
  printf "\e[0m" # ANSI normal
  exit 1
end

# rubocop:enable Rails/Exit
# rubocop:enable Rails/Output
# rubocop:enable Layout/IndentHeredoc
