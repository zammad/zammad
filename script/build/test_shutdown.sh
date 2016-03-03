#!/bin/bash
RAILS_ENV=$1
APP_PORT=$2
WS_PORT=$3
EXIT=$4 || 0

script/scheduler.rb stop
script/websocket-server.rb stop
kill $(cat tmp/pids/server.pid)

rake db:drop

exit $EXIT
