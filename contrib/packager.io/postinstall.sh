#!/bin/bash
#
# packager.io postinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

# import config
. /opt/zammad/contrib/packager.io/config

# import functions
. /opt/zammad/contrib/packager.io/functions

debug

detect_os

detect_docker

detect_initcmd

detect_database

detect_webserver

create_initscripts

stop_zammad

# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/config/database.yml ]; then
    update_database
else
    create_database_password

    if [ "${ADAPTER}" == "postgresql" ]; then
	echo "# Installing zammad on postgresql"
	create_postgresql_db
    elif [ "${ADAPTER}" == "mysql2" ]; then
	echo "# Installing zammad on mysql"
	create_mysql_db
    fi

    update_database_yml

    initialise_database
fi

start_zammad

create_webserver_config

final_message
