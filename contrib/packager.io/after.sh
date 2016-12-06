#!/bin/bash
#
# packager.io after script
#

PATH=$(pwd)/bin:$(pwd)/vendor/bundle/bin:$PATH

set -e

# download locales and translations to make a offline installation possible
gem install bundle
bundle install

rake db:migrate
rake db:seed

rails r 'Locale.fetch'
rails r 'Translation.fetch'

rm -rf tmp/cache*
