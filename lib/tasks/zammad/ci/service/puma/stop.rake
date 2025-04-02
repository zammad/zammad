# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :puma do

        desc 'Stops the puma application webserver'
        task :stop do # rubocop:disable Rails/RakeEnvironment

          command = [
            'script/ci/daemonize.rb',
            'stop',
            '--',
            'puma',
            'bundle exec puma',
          ]

          stdout, stderr, status = Open3.capture3(*command)

          next if status.success? && !stdout.include?('ERROR') # rubocop:disable Rails/NegateInclude

          abort("Error while stopping Puma - error status #{status.exitstatus}: #{stdout} #{stderr}")
        end
      end
    end
  end
end
