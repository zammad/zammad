#!/bin/bash
RAILS_ENV=$1
APP_PORT=$2
WS_PORT=$3
EXIT=$4 || 0
SERVER_PID='tmp/pids/server.pid'

script/scheduler.rb stop
script/websocket-server.rb stop
kill $(cat $SERVER_PID)
sleep 5
if [ -f $SERVER_PID ]; then
   kill -9 $(cat $SERVER_PID)
fi

rake db:drop RAILS_ENV=test
rake db:drop RAILS_ENV=production

exit $EXIT
