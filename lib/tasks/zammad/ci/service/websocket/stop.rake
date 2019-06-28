namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :websocket do

        desc 'Stops the websocket server'
        task :stop do

          command = [
            'bundle',
            'exec',
            'script/websocket-server.rb',
            'stop',
          ]

          _stdout, stderr, status = Open3.capture3(*command)

          next if status.success?

          abort("Error while stopping websocket server - error status #{status.exitstatus}: #{stderr}")
        end
      end
    end
  end
end
