#!/usr/bin/env bash

set -o errexit
set -o pipefail

source /etc/profile.d/rvm.sh
source .gitlab/environment.env

# echo "Running front end tests"
# yarn test
# yarn test:ci:ct

echo "Running basic rspec tests..."
bundle exec rake zammad:db:init
bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb" -t ~searchindex -t ~integration

echo "Running basic minitest tests..."
bundle exec rake zammad:db:reset
bundle exec rake test:units
ruby -I test/ test/integration/object_manager_test.rb