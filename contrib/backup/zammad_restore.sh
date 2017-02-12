#!/bin/bash
#
# zammad restore script
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin:

# import config
. /opt/zammad/contrib/backup/config

# import functions
. /opt/zammad/contrib/backup/functions

# exec restore
restore_warning "${1}"

check_database_config_exists

get_db_credentials

get_restore_dates

choose_restore_date "${1}"

detect_initcmd

stop_zammad

delete_current_files

restore_zammad

start_zammad

restore_message
