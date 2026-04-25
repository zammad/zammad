#!/bin/bash

set -o errexit
set -o pipefail

: "${BACKUP_DIR:=/var/tmp/zammad}"
: "${RESTORE_DIR:=/var/tmp/zammad/restore}"
: "${BACKUP_TIME:=03:00}"
: "${HOLD_DAYS:=10}"

# See DOCKERFILE for environment variables.
ESCAPED_POSTGRESQL_PASS=$(echo "$POSTGRESQL_PASS" | ruby -ruri -e "puts URI.encode_uri_component(readline.chomp)")
POSTGRESQL_URL="postgresql://${POSTGRESQL_USER}:${ESCAPED_POSTGRESQL_PASS}@${POSTGRESQL_HOST}:${POSTGRESQL_PORT}/${POSTGRESQL_DB}"

function check_zammad_ready {
  echo 'Checking if Zammad is ready...'

  # Verify that migrations have been ran and seeds executed to process ENV vars like FQDN correctly.
  until bundle exec rails r 'ActiveRecord::Migration.check_all_pending!; Translation.any? || raise' &> /dev/null; do
    echo "  waiting for init container to finish install or update..."
    sleep 2
  done
}

function zammad_backup {
  TIMESTAMP="$(date +'%Y%m%d%H%M%S')"

  echo "${TIMESTAMP} - backing up zammad..."

  # delete old backups
  if [ -d "${BACKUP_DIR}" ] && [ -n "$(ls "${BACKUP_DIR}")" ]; then
    find "${BACKUP_DIR}" -maxdepth 1 -type f -name "*_zammad_*.gz" -mtime +"${HOLD_DAYS}" -delete
  fi

  if [ "${NO_FILE_BACKUP}" != "yes" ]; then
    # tar files
    tar -czf "${BACKUP_DIR}"/"${TIMESTAMP}"_zammad_files.tar.gz /opt/zammad/storage
  fi

  # backup the database
  pg_dump --dbname="${POSTGRESQL_URL}" | gzip > "${BACKUP_DIR}"/"${TIMESTAMP}"_zammad_db.psql.gz

  echo "backup finished :)"
}

function zammad_backup_loop {
  while true; do
    NOW_TIMESTAMP=$(date +%s)
    TOMORROW_DATE=$(date -d@"$((NOW_TIMESTAMP + 24*60*60))" +%Y-%m-%d)

    zammad_backup

    NEXT_TIMESTAMP=$(date -d "$TOMORROW_DATE $BACKUP_TIME" +%s)
    NOW_TIMESTAMP=$(date +%s)
    SLEEP_SECONDS=$((NEXT_TIMESTAMP - NOW_TIMESTAMP))

    echo "sleeping $SLEEP_SECONDS seconds until the next backup run..."

    sleep $SLEEP_SECONDS
  done
}

function perform_restore {

  function call_psql {
    psql --variable ON_ERROR_STOP=1 --quiet --echo-errors --dbname="${POSTGRESQL_URL}"
  }

  RESTORE_DB_FILE=$(find "${RESTORE_DIR}" -name '*_zammad_db.psql.gz' | sort | tail -n1)
  if [ -z "${RESTORE_DB_FILE}" ]; then
    echo "Error: no database backup found in ${RESTORE_DIR}."
    exit 1
  fi
  echo "Restoring database from ${RESTORE_DB_FILE}…"

  # Clear the database before restoring.
  echo 'DROP SCHEMA PUBLIC CASCADE; CREATE SCHEMA PUBLIC;' | call_psql
  gunzip -c "${RESTORE_DB_FILE}" | call_psql

  RESTORE_STORAGE_FILE=$(find "${RESTORE_DIR}" -name '*_zammad_files.tar.gz' | sort | tail -n1)
  if [ -z "${RESTORE_STORAGE_FILE}" ]; then
    echo "No storage backup found in ${RESTORE_DIR}, skipping."
  else
    echo "Restoring storage from ${RESTORE_STORAGE_FILE}…"
    tar -C / --overwrite -xzf "${RESTORE_STORAGE_FILE}" -v opt/zammad/storage
  fi

  TIMESTAMP="$(date +'%Y%m%d%H%M%S')"
  mv "${RESTORE_DIR}" "${RESTORE_DIR}_completed_${TIMESTAMP}"
  echo "Restore directory was moved to ${RESTORE_DIR}_completed_${TIMESTAMP}. Feel free to delete it."

  echo "Restore completed."
}

if [ -d "${RESTORE_DIR}" ] && [ -n "$(ls "${RESTORE_DIR}")" ]; then
  echo "Restoring from backup directory ${RESTORE_DIR}…"
  perform_restore
else
  check_zammad_ready
  echo "Starting backup loop…"
  zammad_backup_loop
fi
