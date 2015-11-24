#!/bin/bash

while true; do
  read -p "Do you wish to drop the database and execute all browser tests?" yn
  case $yn in
    [Yy]* ) echo "Start tests..."; break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

#export RAILS_ENV=test
export RAILS_ENV=production
export RAILS_SERVE_STATIC_FILES=true

bundle install

rm -rf tmp/screenshot*
rm -rf tmp/cache*
rm -f public/assets/*.css*
rm -f public/assets/*.js*

echo "rake assets:precompile"
time rake assets:precompile

echo "rake db:drop"
time rake db:drop
echo "rake db:create"
time rake db:create
echo "rake db:migrate"
time rake db:migrate
echo "rake db:seed"
time rake db:seed

# modify production.rb to serve assets
sed -i -e 's/config.serve_static_assets = false/config.serve_static_assets = true/' config/environments/production.rb

# set system to develop mode
rails r "Setting.set('developer_mode', true)"

pumactl --pidfile tmp/pids/puma.pid stop
script/websocket-server.rb stop

pumactl start --pidfile tmp/pids/puma.pid -d -p 4445 -e $RAILS_ENV
script/websocket-server.rb start -d
script/scheduler.rb start

sleep 15

#export REMOTE_URL='http://medenhofer:765d0dd4-994b-4e15-9f89-13f3aedeb462@ondemand.saucelabs.com:80/wd/hub' BROWSER_OS='Windows 2012' BROWSER_VERSION=35 BROWSER=firefox
#export REMOTE_URL='http://192.168.178.32:4444/wd/hub'
#export REMOTE_URL='http://192.168.178.45:4444/wd/hub'
export REMOTE_URL='http://10.0.0.9:4444/wd/hub'

export RAILS_ENV=test

echo "rake db:drop"
time rake db:drop
echo "rake db:create"
time rake db:create
echo "rake db:migrate"
time rake db:migrate

rake test:browser["BROWSER_URL=http://localhost:4445"]
#rake test:browser["BROWSER_URL=http://10.0.0.3:4445"]
#rake test:browser["BROWSER_URL=http://localhost:4445 BROWSER=chrome"]
#rake test:browser["BROWSER_URL=http://192.168.178.28:4445"]

script/scheduler.rb stop
script/websocket-server.rb stop
pumactl --pidfile tmp/pids/puma.pid stop

rm -f public/assets/*.css*
rm -f public/assets/*.js*

