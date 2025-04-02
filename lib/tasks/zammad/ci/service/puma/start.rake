# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :puma do

        desc 'Starts the puma application webserver'
        task :start, [:port, :env] do |_task, args| # rubocop:disable Rails/RakeEnvironment
          port     = args.fetch(:port, '3000')
          env      = args.fetch(:env, 'production')

          command = [
            'script/ci/daemonize.rb',
            'start',
            '--',
            'puma',
            "bundle exec puma -p #{port} -e#{env}",
          ]

          stdout, stderr, status = Open3.capture3(*command)

          next if status.success? && !stdout.include?('ERROR') # rubocop:disable Rails/NegateInclude

          abort("Error while starting Puma - error status #{status.exitstatus}: #{stdout} #{stderr}")
        end
      end
    end
  end
end
