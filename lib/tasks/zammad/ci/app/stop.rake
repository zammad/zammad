# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :app do

      desc 'Stops the application'
      task stop: %i[
        zammad:ci:service:background_worker:stop
        zammad:ci:service:websocket:stop
        zammad:ci:service:puma:stop
      ]
    end
  end
end
