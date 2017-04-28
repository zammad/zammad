#!/bin/bash
RAILS_ENV=$1
APP_PORT=$2
WS_PORT=$3
WITH_DB=$4 || 0

if test $WITH_DB -eq 1; then
  script/bootstrap.sh
fi

export ZAMMAD_SETTING_TTL=15

rails r "Setting.set('developer_mode', true)"
rails r "Setting.set('websocket_port', '$WS_PORT')"
rails r "Setting.set('fqdn', '$IP:$BROWSER_PORT')"
rails r "Setting.set('chat_agent_idle_timeout', '45')"

echo "env used for script/build/test_startup.sh $1 $2 $3"
echo "export RAILS_ENV=$RAILS_ENV"
echo "export IP=$IP"
echo "export BROWSER_PORT=$BROWSER_PORT"

#rails s puma -d --pid tmp/pids/server.pid --bind 0.0.0.0 --port $APP_PORT
bundle exec puma --pidfile tmp/pids/server.pid -d -p $APP_PORT -e $RAILS_ENV
bundle exec script/websocket-server.rb start -d -p $WS_PORT
bundle exec script/scheduler.rb start
