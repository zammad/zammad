# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# NOTE: Why use Mysql2::Client over ActiveRecord::Base.connection?
#
# As of Rails 5.2, db:create now runs initializers prior to creating the DB.
# That means if an initializer tries to establish an ActiveRecord::Base.connection,
# it will raise an ActiveRecord::NoDatabaseError
# (see https://github.com/rails/rails/issues/32870 for more details).
#
# The workaround is to use the bare RDBMS library
# and connect without specifying a database.

module Zammad
  class Application
    class Initializer
      module DBPreflightCheck
        module Mysql2
          extend Base

          def self.perform
            check_version_compatibility
            check_max_allowed_packet
          end

          # Configuration check --------------------------------------------------
          # Before MySQL 8.0, the default value of max_allowed_packet was 1MB - 4MB,
          # which is impractically small and can lead to email processing failures.
          #
          # See https://github.com/zammad/zammad/issues/1759
          #     https://github.com/zammad/zammad/issues/1970
          #     https://github.com/zammad/zammad/issues/2034
          def self.check_max_allowed_packet
            if max_allowed_packet_mb <= 4
              err(<<~MSG)
                Database config value 'max_allowed_packet' too small (#{max_allowed_packet_mb}MB)
                Please increase this value in your #{vendor} configuration (64MB+ recommended).
              MSG
            elsif max_allowed_packet_mb < Setting.get('postmaster_max_size').to_i
              warn(<<~MSG)
                Database config value 'max_allowed_packet' less than Zammad setting 'Maximum Email Size'
                Zammad will fail to process emails (both incoming and outgoing)
                larger than the value of 'max_allowed_packet' (#{max_allowed_packet_mb}MB).
                Please increase this value in your #{vendor} configuration accordingly.
              MSG
            end
          rescue ActiveRecord::StatementInvalid
            # Setting.get will fail if 'settings' table does not exist
          end

          def self.connection
            @connection ||= ::Mysql2::Client.new(db_config)
          end

          def self.db_config
            @db_config ||= ActiveRecord::Base.connection_config
                                             .symbolize_keys
                                             .except(:database)
          end

          #  formats: "5.7.3" (MySQL)
          #           "10.1.17-MariaDB" (MariaDB)
          def self.current_version
            @current_version ||= mysql_variable('version').split('-').first
          end

          def self.min_version
            case vendor
            when 'MySQL'
              '5.6'
            when 'MariaDB'
              '10.0'
            end
          end

          def self.vendor
            @vendor ||= mysql_variable('version').split('-').second || 'MySQL'
          end

          def self.max_allowed_packet_mb
            @max_allowed_packet_mb ||= mysql_variable('max_allowed_packet') / 1024 / 1024
          end

          def self.mysql_variable(name)
            connection.query("SELECT @@#{name};").first["@@#{name}"]
          end
        end
      end
    end
  end
end
