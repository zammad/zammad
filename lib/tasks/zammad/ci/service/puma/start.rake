# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :puma do

        desc 'Starts the puma application webserver'
        task :start, [:port, :env] do |_task, args| # rubocop:disable Rails/RakeEnvironment

          port    = args.fetch(:port, '3000')
          env     = args.fetch(:env, 'production')
          command = [
            'bundle',
            'exec',
            'puma',
            '--pidfile',
            'tmp/pids/server.pid',
            '-d',
            '-p',
            port,
            '-e',
            env
          ]

          _stdout, stderr, status = Open3.capture3(*command)

          next if status.success?

          abort("Error while starting Puma - error status #{status.exitstatus}: #{stderr}")
        end
      end
    end
  end
end
