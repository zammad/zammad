#!/bin/bash
#
# zammad backup script
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin:

# import config
. config

# import functions
. functions

delete_old_backups

# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/${DATABASE_CONFIG} ]; then
    get_db_credentials
else
    echo "${ZAMMAD_DIR}/${DATABASE_CONFIG} is missing. is zammad configured yet?"
    exit 1
fi

get_backup_date

backup_dir_create

backup_files

backup_db
