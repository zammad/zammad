namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :scheduler do

        desc 'Starts the scheduler'
        task :start do

          command = [
            'bundle',
            'exec',
            'script/scheduler.rb',
            'start',
          ]

          _stdout, stderr, status = Open3.capture3(*command)

          next if status.success?

          abort("Error while starting scheduler - error status #{status.exitstatus}: #{stderr}")
        end
      end
    end
  end
end
