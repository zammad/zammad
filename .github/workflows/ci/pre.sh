#!/usr/bin/env bash

set -o errexit
set -o pipefail

# shellcheck disable=SC1091
source /etc/profile.d/rvm.sh # ensure RVM is loaded

bundle config set --local frozen 'true'
bundle config set --local path 'vendor'
bundle install -j "$(nproc)"
yarn install
yarn cypress:install
bundle exec ruby .gitlab/configure_environment.rb
