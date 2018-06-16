return if ActiveRecord::Base.connection_config[:adapter] != 'mysql2'

Rails.application.config.db_4bytes_utf8 = false
Rails.application.config.db_null_byte = true
connection = ActiveRecord::Base.connection

# rubocop:disable Rails/Output
# rubocop:disable Rails/Exit
# rubocop:disable Layout/IndentHeredoc

# Version check --------------------------------------------------------------
#  mysql example: "5.7.3"
#  mariadb example: "10.1.17-MariaDB"
server_version = connection.execute('SELECT @@version;').first.first
raise 'Unable to retrive database version' if server_version.blank?
version_number = Gem::Version.new(server_version.split('-').first)
vendor         = server_version.split('-').second || 'MySQL'

case vendor
when 'MySQL'
  if version_number < Gem::Version.new('5.6')
    printf "\e[31m" # ANSI red
    puts <<~MSG
    Error: Incompatible database backend version
    (MySQL 5.6+ required; #{version_number} found)
    MSG
    printf "\e[0m" # ANSI normal
    exit 1
  end
when 'MariaDB'
  if version_number < Gem::Version.new('10.0')
    printf "\e[31m" # ANSI red
    puts <<~MSG
    Error: Incompatible database backend version
    (MariaDB 10.0+ required; #{version_number} found)
    MSG
    printf "\e[0m" # ANSI normal
    exit 1
  end
end

# Configuration check --------------------------------------------------------
# Before MySQL 8.0, the default value of max_allowed_packet was 1MB - 4MB,
# which is impractically small and can lead to failures processing emails.
#
# See https://github.com/zammad/zammad/issues/1759
#     https://github.com/zammad/zammad/issues/1970
#     https://github.com/zammad/zammad/issues/2034
max_allowed_packet = connection.execute('SELECT @@max_allowed_packet;').first.first
max_allowed_packet_mb = max_allowed_packet / 1024 / 1024

if max_allowed_packet_mb <= 4
  printf "\e[31m" # ANSI red
  puts <<~MSG
  Error: Database config value 'max_allowed_packet' too small (#{max_allowed_packet_mb}MB)
  Please increase this value in your #{vendor} configuration (64MB+ recommended).
  MSG
  printf "\e[0m" # ANSI normal
  exit 1
end

if connection.execute("SHOW tables LIKE 'settings';").any? &&
   Setting.get('postmaster_max_size').present? &&
   Setting.get('postmaster_max_size').to_i > max_allowed_packet_mb
  printf "\e[33m" # ANSI yellow
  puts <<~MSG
  Warning: Database config value 'max_allowed_packet' less than Zammad setting 'Maximum Email Size'
  Zammad will fail to process emails (both incoming and outgoing)
  larger than the value of 'max_allowed_packet' (#{max_allowed_packet_mb}MB).
  Please increase this value in your #{vendor} configuration accordingly.
  MSG
  printf "\e[0m" # ANSI normal
end

# rubocop:enable Rails/Exit
# rubocop:enable Rails/Output
# rubocop:enable Layout/IndentHeredoc
