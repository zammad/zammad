web: bundle exec script/rails server -b ${ZAMMAD_BIND_IP:=127.0.0.1} -p ${ZAMMAD_RAILS_PORT:=3000}
websocket: bundle exec script/websocket-server.rb -b ${ZAMMAD_BIND_IP:=127.0.0.1} -p ${ZAMMAD_WEBSOCKET_PORT:=6042} start
worker: bundle exec script/scheduler.rb start -t
