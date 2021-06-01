# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

namespace :zammad do

  desc 'Flushes all logs and caches'
  task flush: %i[
    zammad:flush:logs
    zammad:flush:cache
  ]
end
