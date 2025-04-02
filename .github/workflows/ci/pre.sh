#!/usr/bin/env bash

set -o errexit
set -o pipefail

# shellcheck disable=SC1091
source /etc/profile.d/rvm.sh # ensure RVM is loaded

bundle config set --local deployment 'true'
bundle install -j "$(nproc)"
pnpm install
bundle exec ruby .gitlab/configure_environment.rb
bundle exec rake zammad:db:init
