#!/usr/bin/env bash
#
# install & unit test zammad
#

set -o errexit
set -o pipefail

# install build dependencies
sudo apt-get update
sudo apt-get install -y --no-install-recommends autoconf automake autotools-dev bison build-essential curl git-core libffi-dev libgdbm-dev libgmp-dev libmariadbclient-dev-compat libncurses5-dev libreadline-dev libsqlite3-dev libssl-dev libtool libxml2-dev libxslt1-dev libyaml-0-2 libyaml-dev patch pkg-config postfix sqlite3 zlib1g-dev libimlib2 libimlib2-dev

# create db config
DB_CONFIG="test:\n  adapter: postgresql\n  database: zammad_test\n  host: 127.0.0.1\n  port: DB_PORT\n  pool: 50\n  timeout: 5000\n  encoding: utf8\n  username: DB_USERNAME\n  password: DB_PASSWORD"

if [ "${ZAMMAD_DBS}" == "mysql" ]; then
  DB_ADAPTER="mysql2"
  DB_USERNAME="root"
  DB_PASSWORD="password"
  DB_PORT="13306"
  INSTALL_OPTION="postgres"
elif [ "${ZAMMAD_DBS}" == "postgresql" ]; then
  DB_ADAPTER="postgresql"
  DB_USERNAME="postgres"
  DB_PASSWORD="postgres"
  DB_PORT="5432"
  INSTALL_OPTION="mysql"
fi

echo -e "${DB_CONFIG}" | sed -e "s/adapter: postgresql/adapter: ${DB_ADAPTER}/g" -e "s/DB_USERNAME/${DB_USERNAME}/g" -e "s/DB_PASSWORD/${DB_PASSWORD}/g" -e "s/DB_PORT/${DB_PORT}/g" > config/database.yml

# install zammad
gem install bundler:1.7.3
bundle install --without "${INSTALL_OPTION}"

# unit tests
bundle exec rubocop
bundle exec rake zammad:db:init
bundle exec rspec -t ~type:system -t ~searchindex -t ~required_envs
bundle exec rake zammad:db:reset
bundle exec rake test:units
ruby -I test/ test/integration/object_manager_test.rb
ruby -I test/ test/integration/package_test.rb
