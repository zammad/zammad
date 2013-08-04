#!/bin/bash

while true; do
  read -p "Do you wish to drop database ane execute all browser tests?" yn
  case $yn in
    [Yy]* ) echo "Start tests..."; break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

export RAILS_ENV=test

bundle install

rm -rf tmp/cache/file_store
rm -f public/assets/*.css*
rm -f public/assets/*.js*

#rake assets:precompile

rake db:drop
rake db:create
rake db:migrate
rake db:seed

thin stop
script/websocket-server.rb stop

thin start --threaded -d -p 4444
script/websocket-server.rb start -d

sleep 15

rake test:browser["BROWSER_URL=http://localhost:4444"]

script/websocket-server.rb stop
thin stop

rm -f public/assets/*.css*
rm -f public/assets/*.js*

