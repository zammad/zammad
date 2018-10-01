namespace :zammad do

  desc 'Flushes all logs and caches'
  task flush: %i[
    zammad:flush:logs
    zammad:flush:cache
  ]
end
