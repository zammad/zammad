#!/bin/bash
#
# download translations
#

set -e

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

if [ -n "$(grep zammad_test.sqlite3 < ../config/database.yml)" ]; then
    rm ../config/database.yml
fi
