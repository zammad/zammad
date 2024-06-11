#!/bin/bash

set -e

: "${BACKUP_DIR:=/var/tmp/zammad}"
: "${BACKUP_TIME:=03:00}"
: "${HOLD_DAYS:=10}"

function zammad_backup {
  TIMESTAMP="$(date +'%Y%m%d%H%M%S')"

  echo "${TIMESTAMP} - backing up zammad..."

  # delete old backups
  if [ -d "${BACKUP_DIR}" ] && [ -n "$(ls "${BACKUP_DIR}")" ]; then
    find "${BACKUP_DIR}"/*_zammad_*.gz -type f -mtime +"${HOLD_DAYS}" -delete
  fi

  if [ "${NO_FILE_BACKUP}" != "yes" ]; then
    # tar files
    tar -czf "${BACKUP_DIR}"/"${TIMESTAMP}"_zammad_files.tar.gz /opt/zammad/storage
  fi

  #db backup
  pg_dump --dbname=postgresql://"${POSTGRESQL_USER}:${POSTGRESQL_PASS}@${POSTGRESQL_HOST}:${POSTGRESQL_PORT}/${POSTGRESQL_DB}" | gzip > "${BACKUP_DIR}"/"${TIMESTAMP}"_zammad_db.psql.gz

  echo "backup finished :)"
}

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
