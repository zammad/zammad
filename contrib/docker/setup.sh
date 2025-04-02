#!/usr/bin/env bash
set -e

apt-get update
apt-get upgrade -y

if [ "$1" = 'builder' ]; then
  if [ -z "${COMMIT_SHA}" ]
  then
    echo "Error: the required build argument \$COMMIT_SHA is missing."
    exit 1
  fi

  # Append build information to the Zammad VERSION.
  echo "$(tr -d '\n' < VERSION)-${COMMIT_SHA:0:8}.docker" > VERSION
  echo 'Updated build information in VERSION:'
  cat VERSION

  PACKAGES="build-essential curl git libimlib2-dev libpq-dev libyaml-dev"
elif [ "$1" = 'runner' ]; then
  # Add official PostgreSQL apt repository to not depend on Debian's version.
  #   https://www.postgresql.org/download/linux/debian/
  apt-get install -y postgresql-common
  /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

  PACKAGES="curl libimlib2 libpq5 nginx gnupg postgresql-client-17"
fi

# shellcheck disable=SC2086
apt-get install -y --no-install-recommends ${PACKAGES}
rm -rf /var/lib/apt/lists/*

if [ "$1" = 'builder' ]; then
  cd "${ZAMMAD_DIR}"
  bundle config set --local without 'test development mysql'
  # Don't use the 'deployment' switch here as it would require always using 'bundle exec'
  #   to invoke commands like rails.
  bundle config set --local frozen 'true'
  bundle install

  touch db/schema.rb
  ZAMMAD_SAFE_MODE=1 DATABASE_URL=postgresql://zammad:/zammad bundle exec rake assets:precompile # Don't require Redis or Postgres.

  script/build/cleanup.sh
fi

if [ "$1" = 'runner' ]; then
  groupadd -g 1000 "${ZAMMAD_USER}"
  useradd -M -d "${ZAMMAD_DIR}" -s /bin/bash -u 1000 -g 1000 "${ZAMMAD_USER}"
  sed -i -e "s#user www-data;##g" -e 's#/var/log/nginx/\(access\|error\).log#/dev/stdout#g' -e 's#pid /run/nginx.pid;#pid /tmp/nginx.pid;#g' /etc/nginx/nginx.conf
  mkdir -p "${ZAMMAD_DIR}" /var/log/nginx
  # Pre-create the storage/ and tmp/ folders to avoid mount permission issues (see https://github.com/zammad/zammad/issues/5412).
  mkdir -p "${ZAMMAD_DIR}/storage" "${ZAMMAD_DIR}/tmp"
  chown -R "${ZAMMAD_USER}":"${ZAMMAD_USER}" /etc/nginx /var/lib/nginx /var/log/nginx "${ZAMMAD_DIR}"
fi
