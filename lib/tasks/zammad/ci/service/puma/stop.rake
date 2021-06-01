# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :service do

      namespace :puma do

        desc 'Stops the puma application webserver'
        task :stop do # rubocop:disable Rails/RakeEnvironment

          file = Rails.root.join('tmp/pids/server.pid')
          pid  = File.read(file).to_i

          Process.kill('SIGTERM', pid)

          sleep 5

          next if !File.exist?(file)

          Process.kill('SIGKILL', pid)
        end
      end
    end
  end
end
