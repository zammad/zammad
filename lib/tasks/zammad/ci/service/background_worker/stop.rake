# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :background_worker do

        desc 'Stops the scheduler'
        task :stop do # rubocop:disable Rails/RakeEnvironment

          command = [
            'script/ci/daemonize.rb',
            'start',
            '--',
            'background-worker',
            'bundle exec script/background-worker.rb stop',
          ]

          _stdout, stderr, status = Open3.capture3(*command)

          next if status.success?

          abort("Error while stopping scheduler - error status #{status.exitstatus}: #{stderr}")
        end
      end
    end
  end
end
