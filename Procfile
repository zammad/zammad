web: bundle exec puma -b tcp://${ZAMMAD_BIND:=127.0.0.1}:${ZAMMAD_RAILS_PORT:=3000}
worker: bundle exec script/scheduler.rb start -t
websocket: bundle exec script/websocket-server.rb -b ${ZAMMAD_BIND:=127.0.0.1} -p ${ZAMMAD_WEBSOCKET_PORT:=6042} start
