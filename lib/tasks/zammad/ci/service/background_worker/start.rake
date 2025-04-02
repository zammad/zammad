# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :background_worker do

        desc 'Starts the scheduler'
        task :start do # rubocop:disable Rails/RakeEnvironment

          command = [
            'script/ci/daemonize.rb',
            'start',
            '--',
            'background-worker',
            'bundle exec script/background-worker.rb start',
          ]

          _stdout, stderr, status = Open3.capture3(*command)

          next if status.success?

          abort("Error while starting scheduler - error status #{status.exitstatus}: #{stderr}")
        end
      end
    end
  end
end
