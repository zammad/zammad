#!/bin/bash
RAILS_ENV=$1
PORT=$2

script/scheduler.rb stop
script/websocket-server.rb stop
kill $(cat tmp/pids/puma.pid)
