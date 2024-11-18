#!/usr/bin/env bash
set -e

apt-get update
apt-get upgrade -y

# Add official PostgreSQL apt repository to not depend on Debian's version.
#   https://www.postgresql.org/download/linux/debian/
apt-get install -y postgresql-common
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

if [ "$1" = 'builder' ]; then
  PACKAGES="build-essential curl git libimlib2-dev libpq-dev shared-mime-info postgresql-17"
elif [ "$1" = 'runner' ]; then
  PACKAGES="curl libimlib2 libpq5 nginx gnupg postgresql-client-17"
fi

# shellcheck disable=SC2086
apt-get install -y --no-install-recommends ${PACKAGES}
rm -rf /var/lib/apt/lists/*

if [ "$1" = 'builder' ]; then
  # Create an empty DB just so that the Rails stack can run.
  /etc/init.d/postgresql start
  su - postgres bash -c "createuser zammad -R -S"
  su - postgres bash -c "createdb --encoding=utf8 --owner=zammad zammad"

  cd "${ZAMMAD_DIR}"
  bundle config set --local without 'test development mysql'
  # Don't use the 'deployment' switch here as it would require always using 'bundle exec'
  #   to invoke commands like rails.
  bundle config set --local frozen 'true'
  bundle install

  touch db/schema.rb
  ZAMMAD_SAFE_MODE=1 DATABASE_URL=postgresql://zammad:/zammad bundle exec rake assets:precompile # Don't require Redis.

  script/build/cleanup.sh
fi

if [ "$1" = 'runner' ]; then
  groupadd -g 1000 "${ZAMMAD_USER}"
  useradd -M -d "${ZAMMAD_DIR}" -s /bin/bash -u 1000 -g 1000 "${ZAMMAD_USER}"
  sed -i -e "s#user www-data;##g" -e 's#/var/log/nginx/\(access\|error\).log#/dev/stdout#g' -e 's#pid /run/nginx.pid;#pid /tmp/nginx.pid;#g' /etc/nginx/nginx.conf
  mkdir -p "${ZAMMAD_DIR}" /var/log/nginx
  mkdir -p "${ZAMMAD_DIR}/storage"  # Pre-create the storage folder to avoid mount permission issues (see https://github.com/zammad/zammad/issues/5412).
  chown -R "${ZAMMAD_USER}":"${ZAMMAD_USER}" /etc/nginx /var/lib/nginx /var/log/nginx "${ZAMMAD_DIR}"
fi
