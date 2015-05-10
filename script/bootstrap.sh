#!/bin/bash

bundle install

rm -rf tmp/cache_file_store_*

rake db:create
rake db:migrate
rake db:seed
