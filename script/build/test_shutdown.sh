#!/bin/bash
RAILS_ENV=$1
APP_PORT=$2
WS_PORT=$3
EXIT=$4 || 0
WITH_DB=$5 || 0

SERVER_PID='tmp/pids/server.pid'
LOG_HOST='cilog@schneeberg.znuny.com'

bundle exec script/scheduler.rb stop
bundle exec script/websocket-server.rb stop
kill $(cat $SERVER_PID)
sleep 5
if [ -f $SERVER_PID ]; then
   kill -9 $(cat $SERVER_PID)
fi

if test $WITH_DB -eq 1; then
  script/build/test_cleanup.sh
fi

# if build has failed, copy logs for analyzing
if test $EXIT -eq 1; then
  ssh $LOG_HOST "mkdir -p logs/$CI_BUILD_ID"
  scp -C log/* $LOG_HOST:logs/$CI_BUILD_ID/
  scp -C tmp/screenshot* $LOG_HOST:logs/$CI_BUILD_ID/
fi

exit $EXIT
