# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :ci do

    namespace :app do

      desc 'Restarts the application'
      task restart: %i[
        zammad:ci:app:stop
        zammad:ci:app:start
      ]
    end
  end
end
