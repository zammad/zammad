#!/bin/bash

while true; do
  read -p "Do you wish to drop database ane execute all browser tests?" yn
  case $yn in
    [Yy]* ) echo "Start tests..."; break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

#export RAILS_ENV=test
export RAILS_ENV=production

bundle install

rm -rf tmp/cache/file_store
rm -f public/assets/*.css*
rm -f public/assets/*.js*

rake assets:precompile

rake db:drop
rake db:create
rake db:migrate
rake db:seed

# modify production.rb to serve assets
cat config/environments/production.rb | sed -e 's/config.serve_static_assets = false/config.serve_static_assets = true/' > /tmp/production.rb && cp /tmp/production.rb config/environments/production.rb

# mofidy auth backend
cat lib/auth/test.rb | sed 's/test/production/' > /tmp/test.rb && cp /tmp/test.rb lib/auth/test.rb

pumactl --pidfile tmp/pids/puma.pid stop
script/websocket-server.rb stop

pumactl start --pidfile tmp/pids/puma.pid -d -p 4444 -e $RAILS_ENV
script/websocket-server.rb start -d

sleep 15

#export REMOTE_URL='http://medenhofer:765d0dd4-994b-4e15-9f89-13f3aedeb462@ondemand.saucelabs.com:80/wd/hub' BROWSER_OS='Windows 2012' BROWSER_VERSION=20 BROWSER=firefox

rake test:browser["BROWSER_URL=http://localhost:4444"]
#rake test:browser["BROWSER_URL=http://192.168.178.20:4444"]


script/websocket-server.rb stop
pumactl --pidfile tmp/pids/puma.pid stop

rm -f public/assets/*.css*
rm -f public/assets/*.js*

