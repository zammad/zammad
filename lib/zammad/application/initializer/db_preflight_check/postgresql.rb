# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# NOTE: Why use PG::Connection over ActiveRecord::Base.connection?
#
# As of Rails 5.2, db:create now runs initializers prior to creating the DB.
# That means if an initializer tries to establish an ActiveRecord::Base.connection,
# it will raise an ActiveRecord::NoDatabaseError
# (see https://github.com/rails/rails/issues/32870 for more details).
#
# The workaround is to use the bare RDBMS library
# and connect to a standard system database instead.

module Zammad
  class Application
    class Initializer
      module DBPreflightCheck
        module Postgresql
          extend Base

          def self.perform
            check_version_compatibility
          ensure
            connection.try(:finish)
          end

          def self.check_version_compatibility
            return if connection.nil? # Edge case: if Postgres can't find a DB to connect to

            super
          end

          def self.connection
            alternate_dbs = %w[template0 template1 postgres]

            @connection ||= begin
              PG.connect(db_config)
            rescue PG::ConnectionBad
              db_config[:dbname] = alternate_dbs.pop
              retry if db_config[:dbname].present?
            end
          end

          # Adapted from ActiveRecord::ConnectionHandling#postgresql_connection
          def self.db_config
            @db_config ||= ActiveRecord::Base.connection_config.dup.tap do |config|
              config.symbolize_keys!
              config[:user] = config.delete(:username)
              config[:dbname] = config.delete(:database)
              config.slice!(*PG::Connection.conndefaults_hash.keys, :requiressl)
              config.compact!
            end
          end

          #  formats: "9.5.0"
          #           "10.3 (Debian 10.3-2)"
          def self.current_version
            @current_version ||= pg_variable('server_version').split.first
          end

          def self.min_version
            @min_version ||= '9.1'
          end

          def self.vendor
            @vendor ||= 'PostgreSQL'
          end

          def self.pg_variable(name)
            connection.exec("SHOW #{name};").first[name]
          end
        end
      end
    end
  end
end
