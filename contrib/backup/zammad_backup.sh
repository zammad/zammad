#!/usr/bin/env bash
#
# zammad backup script
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin:
BACKUP_SCRIPT_PATH="$(dirname $(realpath $0))"

if [ -f "${BACKUP_SCRIPT_PATH}/config" ]; then
  # Ensure we're inside of our Backup-Script folder (see issue 2508)
  cd "${BACKUP_SCRIPT_PATH}"

  # import config
  . ${BACKUP_SCRIPT_PATH}/config
else
  echo -e "\n The 'config' file is missing!"
  echo -e " Please copy ${BACKUP_SCRIPT_PATH}/config.dist to  ${BACKUP_SCRIPT_PATH}/config before running $0!\n"
  exit 1
fi

# import functions
. ${BACKUP_SCRIPT_PATH}/functions

# exec backup
start_backup_message

get_zammad_dir

check_database_config_exists

delete_old_backups

get_backup_date

backup_dir_create

backup_files

backup_db

finished_backup_message
