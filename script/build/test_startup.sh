#!/bin/bash
RAILS_ENV=$1
PORT=$2

pumactl start --pidfile tmp/pids/puma.pid -d -p $PORT -e $RAILS_ENV
script/websocket-server.rb start -d
script/scheduler.rb start
