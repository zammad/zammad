#!/bin/bash

bundle install

rm -rf tmp/cache*

rake db:drop
rake db:create
rake db:migrate
rake db:seed
