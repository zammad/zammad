#!/usr/bin/env sh

env

# Ensure proper permissions on root-mounted volume.
sudo chown -R "${USER}" node_modules

bin/setup --skip-server

bundle exec bootsnap precompile --gemfile app/ lib/

bundle exec rails r "Setting.set('es_url', 'http://elasticsearch:9200')"

bundle exec rails zammad:setup:auto_wizard
