# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :scheduler do

        desc 'Stops the scheduler'
        task :stop do # rubocop:disable Rails/RakeEnvironment

          command = [
            'bundle',
            'exec',
            'script/scheduler.rb',
            'stop',
          ]

          _stdout, stderr, status = Open3.capture3(*command)

          next if status.success?

          abort("Error while stopping scheduler - error status #{status.exitstatus}: #{stderr}")
        end
      end
    end
  end
end
