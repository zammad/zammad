require 'zammad/application/initializer/db_preflight_check/base'
require 'zammad/application/initializer/db_preflight_check/mysql2'
require 'zammad/application/initializer/db_preflight_check/postgresql'

module Zammad
  class Application
    class Initializer
      module DBPreflightCheck
        def self.perform
          adapter.perform
        end

        def self.adapter
          @adapter ||= const_get(ActiveRecord::Base.connection_config[:adapter].capitalize)
        end
      end
    end
  end
end
