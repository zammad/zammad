# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
