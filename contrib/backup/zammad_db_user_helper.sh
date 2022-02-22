#!/usr/bin/env bash
#
# This little helper script 

# shellcheck disable=SC2046
BACKUP_SCRIPT_PATH="$(dirname $(realpath $0))"

# import functions
. ${BACKUP_SCRIPT_PATH}/functions

# exec backup
start_helper_message

get_zammad_dir

db_helper_warning

check_database_config_exists

detect_initcmd

stop_zammad

db_helper_alter_user

start_zammad
