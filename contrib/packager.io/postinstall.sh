#!/bin/bash
#
# packager.io postinstall script
#
set -ex

# create init scripts
/usr/bin/zammad scale web=1 websocket=1 worker=1

# stop zammad
systemctl stop zammad

# db migration
if /usr/bin/zammad config:get DATABASE_URL ; then
    /usr/bin/zammad run rake db:migrate
fi

# start zammad
systemctl restart zammad

