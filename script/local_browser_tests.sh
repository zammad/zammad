#!/bin/bash

while true; do
  read -p "Do you wish to drop database ane execute all browser tests?" yn
  case $yn in
    [Yy]* ) echo "Start tests..."; break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

bundle install

rm -rf tmp/cache/file_store

rake db:drop
rake db:create
rake db:migrate
rake db:seed

thin start --threaded -d -p 4444

sleep 15

rake test:browser["BROWSER_URL=http://localhost:4444"]

thin stop

