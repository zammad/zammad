# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  class Application
    module Initializer
      module DbPreflightCheck

        MIN_VERSION = '13'.freeze

        class << self

          def perform
            check_version_compatibility
          ensure
            connection.try(:finish)
          end

          private

          def check_version_compatibility
            return if connection.nil? # Edge case: if Postgres can't find a DB to connect to

            return if Gem::Version.new(current_version) >= Gem::Version.new(MIN_VERSION)

            warn "Error: incompatible database backend version (PostgreSQL #{MIN_VERSION}+ required; #{current_version} found)."
            exit 1 # rubocop:disable Rails/Exit
          end

          def connection
            alternate_dbs = %w[template0 template1 postgres]

            @connection ||= begin
              PG.connect(**db_config)
            rescue PG::ConnectionBad
              db_config[:dbname] = alternate_dbs.pop
              retry if db_config[:dbname].present?
            end
          end

          # Adapted from ActiveRecord::ConnectionHandling#postgresql_connection
          def db_config
            @db_config ||= ActiveRecord::Base.connection_db_config.configuration_hash.dup.tap do |config|
              config.symbolize_keys!
              config[:user] = config.delete(:username)
              config[:dbname] = config.delete(:database)
              config.slice!(*PG::Connection.conndefaults_hash.keys, :requiressl)
              config.compact!
            end
          end

          #  formats: "9.5.0"
          #           "10.3 (Debian 10.3-2)"
          def current_version
            @current_version ||= pg_variable('server_version').split.first
          end

          def pg_variable(name)
            connection.exec("SHOW #{name};").first[name]
          end
        end
      end
    end
  end
end
