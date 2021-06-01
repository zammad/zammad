# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :websocket do

        desc 'Starts the websocket server'
        task :start, [:port] do |_task, args| # rubocop:disable Rails/RakeEnvironment

          port    = args.fetch(:port, '6042')
          command = [
            'bundle',
            'exec',
            'script/websocket-server.rb',
            'start',
            '-d',
            '-p',
            port
          ]

          _stdout, stderr, status = Open3.capture3(*command)

          next if status.success?

          abort("Error while starting websocket server - error status #{status.exitstatus}: #{stderr}")
        end
      end
    end
  end
end
