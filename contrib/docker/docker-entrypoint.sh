#!/usr/bin/env bash

set -e

: "${AUTOWIZARD_JSON:=''}"
: "${AUTOWIZARD_RELATIVE_PATH:='tmp/auto_wizard.json'}"
: "${ELASTICSEARCH_ENABLED:=true}"
: "${ELASTICSEARCH_HOST:=zammad-elasticsearch}"
: "${ELASTICSEARCH_PORT:=9200}"
: "${ELASTICSEARCH_SCHEMA:=http}"
: "${ELASTICSEARCH_NAMESPACE:=zammad}"
: "${ELASTICSEARCH_REINDEX:=true}"
: "${ELASTICSEARCH_SSL_VERIFY:=true}"
: "${NGINX_PORT:=8080}"
: "${NGINX_SERVER_NAME:=_}"
: "${NGINX_SERVER_SCHEME:=\$scheme}"
: "${POSTGRESQL_DB:=zammad_production}"
: "${POSTGRESQL_DB_CREATE:=true}"
: "${POSTGRESQL_HOST:=zammad-postgresql}"
: "${POSTGRESQL_PORT:=5432}"
: "${POSTGRESQL_USER:=zammad}"
: "${POSTGRESQL_PASS:=zammad}"
: "${POSTGRESQL_OPTIONS:=}"
: "${RAILS_ENV:=production}"
: "${RAILS_LOG_TO_STDOUT:=true}"
: "${RAILS_TRUSTED_PROXIES:=127.0.0.1,::1}"
: "${ZAMMAD_DIR:=/opt/zammad}"
: "${ZAMMAD_RAILSSERVER_HOST:=zammad-railsserver}"
: "${ZAMMAD_RAILSSERVER_PORT:=3000}"
: "${ZAMMAD_WEBSOCKET_HOST:=zammad-websocket}"
: "${ZAMMAD_WEBSOCKET_PORT:=6042}"
: "${ZAMMAD_WEB_CONCURRENCY:=0}"

ESCAPED_POSTGRESQL_PASS=$(echo "$POSTGRESQL_PASS" | sed -e 's/[\/&]/\\&/g')
export DATABASE_URL="postgres://${POSTGRESQL_USER}:${ESCAPED_POSTGRESQL_PASS}@${POSTGRESQL_HOST}:${POSTGRESQL_PORT}/${POSTGRESQL_DB}${POSTGRESQL_OPTIONS}"

function check_zammad_ready {
  # Verify that migrations have been ran and seeds executed to process ENV vars like FQDN correctly.
  until bundle exec rails r 'ActiveRecord::Migration.check_all_pending!; Locale.any? || raise' &> /dev/null; do
    echo "waiting for init container to finish install or update..."
    sleep 5
  done
}

# zammad init
if [ "$1" = 'zammad-init' ]; then
  # install / update zammad
  until (echo > /dev/tcp/"${POSTGRESQL_HOST}"/"${POSTGRESQL_PORT}") &> /dev/null; do
    echo "waiting for postgresql server to be ready..."
    sleep 5
  done

  # check if database exists / update to new version
  echo "initialising / updating database..."
  if ! (bundle exec rails r 'puts User.any?' 2> /dev/null | grep -q true); then
    if [ "${POSTGRESQL_DB_CREATE}" == "true" ]; then
      bundle exec rake db:create
    fi
    bundle exec rake db:migrate
    bundle exec rake db:seed

    # create autowizard.json on first install
    if base64 -d <<< "${AUTOWIZARD_JSON}" &>> /dev/null; then
      echo "Saving autowizard json payload..."
      base64 -d <<< "${AUTOWIZARD_JSON}" > "${AUTOWIZARD_RELATIVE_PATH}"
    fi
  else
    echo Clearing cache...
    bundle exec rails r "Rails.cache.clear"

    echo Executing migrations...
    bundle exec rake db:migrate

    echo Synchronizing locales...
    bundle exec rails r "Locale.sync"

    echo Synchronizing translations...
    bundle exec rails r "Translation.sync"
  fi

  # es config
  echo "changing settings..."
  if [ "${ELASTICSEARCH_ENABLED}" == "false" ]; then
    bundle exec rails r "Setting.set('es_url', '')"
  else
    bundle exec rails r "Setting.set('es_url', '${ELASTICSEARCH_SCHEMA}://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}')"

    bundle exec rails r "Setting.set('es_index', '${ELASTICSEARCH_NAMESPACE}')"

    if [ -n "${ELASTICSEARCH_USER}" ] && [ -n "${ELASTICSEARCH_PASS}" ]; then
      bundle exec rails r "Setting.set('es_user', \"${ELASTICSEARCH_USER}\")"
      bundle exec rails r "Setting.set('es_password', \"${ELASTICSEARCH_PASS}\")"
    fi

    until (echo > /dev/tcp/"${ELASTICSEARCH_HOST}/${ELASTICSEARCH_PORT}") &> /dev/null; do
      echo "zammad railsserver waiting for elasticsearch server to be ready..."
      sleep 5
    done

    if [ "${ELASTICSEARCH_SSL_VERIFY}" == "false" ]; then
      SSL_SKIP_VERIFY="-k"
    else
      SSL_SKIP_VERIFY=""
    fi

    if [ "${ELASTICSEARCH_REINDEX}" == "true" ]; then
      if ! curl -s "${SSL_SKIP_VERIFY}" "${ELASTICSEARCH_SCHEMA}://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_cat/indices" | grep -q zammad; then
        echo "rebuilding es searchindex..."
        bundle exec rake zammad:searchindex:rebuild
      fi
    fi
  fi

# zammad nginx
elif [ "$1" = 'zammad-nginx' ]; then
  check_zammad_ready

  # configure nginx
  sed -e "s#\(listen\)\(.*\)80#\1\2${NGINX_PORT}#g" \
      -e "s#proxy_set_header X-Forwarded-Proto .*;#proxy_set_header X-Forwarded-Proto ${NGINX_SERVER_SCHEME};#g" \
      -e "s#server .*:3000#server ${ZAMMAD_RAILSSERVER_HOST}:${ZAMMAD_RAILSSERVER_PORT}#g" \
      -e "s#server .*:6042#server ${ZAMMAD_WEBSOCKET_HOST}:${ZAMMAD_WEBSOCKET_PORT}#g" \
      -e "s#server_name .*#server_name ${NGINX_SERVER_NAME};#g" \
      -e 's#/var/log/nginx/zammad.\(access\|error\).log#/dev/stdout#g' < contrib/nginx/zammad.conf > /etc/nginx/sites-enabled/default

  echo "starting nginx..."

  exec /usr/sbin/nginx -g 'daemon off;'

# zammad-railsserver
elif [ "$1" = 'zammad-railsserver' ]; then
  check_zammad_ready

  echo "starting railsserver... with WEB_CONCURRENCY=${ZAMMAD_WEB_CONCURRENCY}"

  #shellcheck disable=SC2101
  exec bundle exec puma -b tcp://[::]:"${ZAMMAD_RAILSSERVER_PORT}" -w "${ZAMMAD_WEB_CONCURRENCY}" -e "${RAILS_ENV}"

# zammad-scheduler
elif [ "$1" = 'zammad-scheduler' ]; then
  check_zammad_ready

  echo "starting background services..."

  exec bundle exec script/background-worker.rb start

# zammad-websocket
elif [ "$1" = 'zammad-websocket' ]; then
  check_zammad_ready

  echo "starting websocket server..."

  exec bundle exec script/websocket-server.rb -b 0.0.0.0 -p "${ZAMMAD_WEBSOCKET_PORT}" start

# zammad-backup
elif [ "$1" = 'zammad-backup' ]; then
  check_zammad_ready

  echo "starting backup..."

  exec contrib/docker/backup.sh

# Pass all other container commands to shell
else
  exec "$@"
fi
