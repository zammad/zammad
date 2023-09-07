#!/usr/bin/env bash

set -o errexit
set -o pipefail

# shellcheck disable=SC1091
source /etc/profile.d/rvm.sh
# shellcheck disable=SC1091
source .gitlab/environment.env

echo "Checking assets generation..."
bundle exec rake assets:precompile

echo "Running front end tests..."
yarn test
yarn test:ci:ct

echo "Running basic rspec tests..."
bundle exec rake zammad:db:init
#bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb" -t ~searchindex -t ~integration -t ~required_envs
gem install semaphore_test_boosters
TEST_BOOSTERS_RSPEC_TEST_EXCLUDE_PATTERN='spec/system/**/*_spec.rb' TB_RSPEC_OPTIONS="-t ~searchindex -t ~integration -t ~required_envs" rspec_booster --job "${JOB_INDEX}/${JOB_COUNT}"

echo "Running basic minitest tests..."
bundle exec rake zammad:db:reset
bundle exec rake test:units
