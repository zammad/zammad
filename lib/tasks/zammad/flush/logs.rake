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
