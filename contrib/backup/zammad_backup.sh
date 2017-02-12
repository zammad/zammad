#!/bin/bash
#
# zammad backup script
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin:

# import config
. config

# import functions
. functions

# exec backup
delete_old_backups

check_database_config_exists

get_backup_date

backup_dir_create

backup_files

backup_db
