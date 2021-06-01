# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# NOTE: Why use Mysql2::Client / PG::Connection over ActiveRecord::Base.connection?
#
# As of Rails 5.2, db:create now runs initializers prior to creating the DB.
# That means if an initializer tries to establish an ActiveRecord::Base.connection,
# it will raise an ActiveRecord::NoDatabaseError
# (see https://github.com/rails/rails/issues/32870 for more details).
#
# The workaround is to use the bare RDBMS library
# and connect without specifying a database (MySQL),
# or connect to a standard system database instead (PostgreSQL).

module Zammad
  class Application
    class Initializer
      module DBPreflightCheck
        module Base
          def check_version_compatibility
            return if Gem::Version.new(current_version) >= Gem::Version.new(min_version)

            err(<<~MSG)
              Incompatible database backend version
              (#{vendor} #{min_version}+ required; #{current_version} found)
            MSG
          end

          def warn(msg)
            printf "\e[33m" # ANSI yellow
            puts "Warning: #{msg}" # rubocop:disable Rails/Output
            printf "\e[0m" # ANSI normal
          end

          def err(msg)
            printf "\e[31m" # ANSI red
            puts "Error: #{msg}" # rubocop:disable Rails/Output
            printf "\e[0m" # ANSI normal

            exit 1 # rubocop:disable Rails/Exit
          end
        end
      end
    end
  end
end
