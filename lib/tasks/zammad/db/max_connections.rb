# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  module DB
    class MaxConnections

      def calculate
        puts "Connections pool size: #{pool_size}"
        puts "Total Zammad processes: #{total_processes}"
        puts "Recommended PostgreSQL max_connections value: #{max_connections}"

        max_connections
      end

      private

      def pool_size
        @pool_size ||= ActiveRecord::Base.connection_pool.size
      end

      def total_processes
        @total_processes ||= calculate_web + calculate_background_services + calculate_others + calculate_websocket
      end

      def max_connections
        @max_connections ||= pool_size * total_processes
      end

      def calculate_web
        web_servers     = ask('How many web server instances/pods do you have? (DEFAULT=1)',
                              default: 1, env_var: 'ZAMMAD_MAX_CONNECTIONS_WEB_SERVERS')
        web_concurrency = (ENV['ZAMMAD_WEB_CONCURRENCY'] || ENV['WEB_CONCURRENCY'] || 0).to_i

        puts "WEB_CONCURRENCY=#{web_concurrency}"

        web_concurrency = 1 if !web_concurrency.positive?

        web_concurrency * web_servers
      end

      def calculate_background_services
        BackgroundServices
          .available_services
          .map { |elem| "ZAMMAD_#{elem.name.demodulize.underscore.upcase}_WORKERS" }
          .reduce(1) do |memo, elem| # Main process always runs
            workers = (ENV[elem] || 0).to_i
            puts "#{elem}=#{workers}"

            memo + workers
          end
      end

      def calculate_others
        cronjobs = ask('Do you have any cronjobs running Zammad, how many run concurrently? (DEFAULT=0)',
                       default: 0, env_var: 'ZAMMAD_MAX_CONNECTIONS_CONCURRENT_CRONJOBS')
        manual   = ask('Do you have any other processes running Zammad via rails command, how many run concurrently? (DEFAULT=0)',
                       default: 0, env_var: 'ZAMMAD_MAX_CONNECTIONS_CONCURRENT_MANUAL')

        cronjobs + manual
      end

      def calculate_websocket
        1
      end

      def ask(question, default: nil, env_var: nil)
        if env_var.present? && ENV[env_var].present?
          value = ENV[env_var]

          if value.to_i.to_s == value
            puts "#{env_var}=#{value}"
            return value.to_i
          end

          puts "Environment variable #{env_var} is set to #{value}, but could not be read as integer."
        end

        print "#{question} "

        loop do
          number = $stdin.gets.chomp

          if number.blank? && default.present?
            return default
          end

          if number.to_i.to_s == number
            return number.to_i
          end

          puts 'Your input could not be read, please enter an integer.'
        end
      end
    end
  end
end
