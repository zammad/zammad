#!/bin/bash

bundle install --jobs 8

rm -rf tmp/cache*

export Z_LOCALES='en-us:de-de'

bundle exec rake db:drop
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed
