#!/usr/bin/env bash
set -e

if [ "$1" = 'builder' ]; then
  PACKAGES="build-essential curl git libimlib2-dev libpq-dev shared-mime-info"
elif [ "$1" = 'runner' ]; then
  PACKAGES="curl libimlib2 libpq5 nginx rsync"
fi

apt-get update
apt-get upgrade -y
# shellcheck disable=SC2086
apt-get install -y --no-install-recommends ${PACKAGES}
rm -rf /var/lib/apt/lists/*

if [ "$1" = 'builder' ]; then
  cd "${ZAMMAD_TMP_DIR}"
  bundle config set without 'test development mysql'
  bundle install
  sed -e 's#.*adapter: postgresql#  adapter: nulldb#g' -e 's#.*username:.*#  username: postgres#g' -e 's#.*password:.*#  password: \n  host: zammad-postgresql\n#g' < contrib/packager.io/database.yml.pkgr > config/database.yml
  sed -i "/require 'rails\/all'/a require\ 'nulldb'" config/application.rb
  touch db/schema.rb
  bundle exec rake assets:precompile
  rm -r tmp/cache
  script/build/cleanup.sh
fi

if [ "$1" = 'runner' ]; then
  groupadd -g 1000 "${ZAMMAD_USER}"
  useradd -M -d "${ZAMMAD_DIR}" -s /bin/bash -u 1000 -g 1000 "${ZAMMAD_USER}"
  sed -i -e "s#user www-data;##g" -e 's#/var/log/nginx/\(access\|error\).log#/dev/stdout#g' -e 's#pid /run/nginx.pid;#pid /tmp/nginx.pid;#g' /etc/nginx/nginx.conf
  mkdir -p "${ZAMMAD_DIR}" /var/log/nginx
  chown -R "${ZAMMAD_USER}":"${ZAMMAD_USER}" /etc/nginx /var/lib/nginx /var/log/nginx "${ZAMMAD_DIR}" "${ZAMMAD_TMP_DIR}" 
fi
