#!/bin/bash
#
# download localistaions
#

RAILS_ENV="test"

#set -e

# download locales and translations to make a offline installation possible
gem install bundle
bundle install

cp ../config/database.yml.test-sqlite ../config/database.yml

rake db:migrate
rake db:seed

rails r 'Locale.fetch'
rails r 'Translation.fetch'

rake db:drop

rm -rf ../tmp/cache*

if [ -n "$(cat ../config/database.yml| grep zammad_test.sqlite3)" ]; then
    rm ../config/database.yml
fi
