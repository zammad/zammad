#!/bin/bash

bundle install

rm -rf tmp/cache/file_store

rake db:create
rake db:migrate
rake db:seed

