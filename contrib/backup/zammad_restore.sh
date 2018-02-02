#!/usr/bin/env bash
#
# zammad restore script
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin:
BACKUP_SCRIPT_PATH="$(dirname $(realpath $0))"

if [ -f "${BACKUP_SCRIPT_PATH}/config" ]; then
  # import config
  . ${BACKUP_SCRIPT_PATH}/config
else
  echo -e "\n The 'config' file is missing!"
  echo -e " Please copy ${BACKUP_SCRIPT_PATH}/config.dist to  ${BACKUP_SCRIPT_PATH}/config before running $0!\n"
  exit 1
fi

# import functions
. ${BACKUP_SCRIPT_PATH}/functions

# exec restore
start_restore_message

get_zammad_dir

restore_warning "${1}"

check_database_config_exists

get_restore_dates

choose_restore_date "${1}"

detect_initcmd

stop_zammad

restore_zammad

start_zammad

finished_restore_message
