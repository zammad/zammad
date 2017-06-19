#!/bin/bash
#
# packager.io postinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

# import config
. /opt/zammad/contrib/packager.io/config

# import functions
. /opt/zammad/contrib/packager.io/functions

# exec postinstall
debug

detect_os

detect_docker

detect_initcmd

detect_database

detect_webserver

create_initscripts

stop_zammad

update_or_install

set_env_vars

start_zammad

create_webserver_config

final_message
