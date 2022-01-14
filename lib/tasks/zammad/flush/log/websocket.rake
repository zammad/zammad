# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :flush do

    namespace :log do

      desc 'Flushes all websocket server log files'
      task :websocket do # rubocop:disable Rails/RakeEnvironment
        %w[err out].each do |suffix|
          File.write(Rails.root.join('log', "websocket-server_#{suffix}.log"), '')
        end
      end
    end
  end
end
