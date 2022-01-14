# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

namespace :zammad do

  namespace :flush do

    desc 'Flushes all logs'
    task logs: %i[
      zammad:flush:log:rails
      zammad:flush:log:scheduler
      zammad:flush:log:websocket
    ]
  end
end
