#!/usr/bin/env bash
#
# install & unit test zammad
#

set -o errexit
set -o pipefail

DB_CONFIG="test:\n  adapter: postgresql\n  database: zammad_test\n  host: 127.0.0.1\n  pool: 50\n  timeout: 5000\n  encoding: utf8\n  username: zammad_test\n  password: zammad_test"

# install build dependencies
sudo apt-get update
sudo apt-get install -y --no-install-recommends autoconf automake autotools-dev bison build-essential curl git-core libffi-dev libgdbm-dev libgmp-dev libmariadbclient-dev-compat libncurses5-dev libreadline-dev libsqlite3-dev libssl-dev libtool libxml2-dev libxslt1-dev libyaml-0-2 libyaml-dev patch pkg-config postfix sqlite3 zlib1g-dev

if [ "${CIRCLE_JOB}" == "install-mysql" ]; then
  DB_ADAPTER="mysql2"
  INSTALL_OPTION="postgres"
elif [ "${CIRCLE_JOB}" == "install-postgresql" ]; then
  DB_ADAPTER="postgresql"
  INSTALL_OPTION="mysql"
else
  echo "nothing to do for circle ci job ${CIRCLE_JOB}..."
  exit 0
fi

# create db config
echo -e "${DB_CONFIG}" | sed "s/adapter: postgresql/adapter: ${DB_ADAPTER}/g" > config/database.yml

# install zammad
bundle install --without "${INSTALL_OPTION}"

# unit tests
bundle exec rubocop
rake db:migrate
rake db:seed
bundle exec rspec -t ~type:system
bundle exec rake db:environment:set RAILS_ENV=test
rake db:reset
rake test:units
ruby -I test/ test/integration/object_manager_test.rb
ruby -I test/ test/integration/package_test.rb
