#!/bin/bash
#
# packager.io postinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

ZAMMAD_DIR="/opt/zammad"
DB="zammad_production"
DB_USER="zammad"

# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/config/database.yml ]; then
    # get existing db pass
    DB_PASS="$(grep "password:" < ${ZAMMAD_DIR}/config/database.yml | sed 's/.*password://')"
fi

# check if db pass exists
if [ -z "${DB_PASS}" ]; then
    # create new db pass
    DB_PASS="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c10)"

    # create database
    cd /tmp
    su - postgres -c "createdb -E UTF8 ${DB}"

    # create postgres user
    echo "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" | su - postgres -c psql 

    # grant privileges
    echo "GRANT ALL PRIVILEGES ON DATABASE \"${DB}\" TO \"${DB_USER}\";" | su - postgres -c psql

    # update configfile
    sed -e "s/  password:/  password: ${DB_PASS}/" < ${ZAMMAD_DIR}/config/database.yml.pkgr > ${ZAMMAD_DIR}/config/database.yml

    # zammad config set
    zammad config:set DATABASE_URL=postgres://${DB_USER}:${DB_PASS}@127.0.0.1/${DB}

    # fill database
    zammad run rake db:migrate 
    zammad run rake db:seed
fi

# create init scripts
zammad scale web=1 websocket=1 worker=1

# stop zammad
systemctl stop zammad

# db migration
zammad run rake db:migrate

# start zammad
systemctl start zammad

# nginx config
if [ -d /etc/nginx/sites-enabled ]; then
    # copy nginx config 
    test -f /etc/nginx/sites-available/zammad.conf || cp ${ZAMMAD_DIR}/contrib/nginx/sites-available/zammad.conf /etc/nginx/sites-available/zammad.conf
    # creating symlink
    test -f /etc/nginx/sites-available/zammad.conf || ln -s /etc/nginx/sites-available/zammad.conf /etc/nginx/sites-enabled/zammad.conf
    # restart nginx
    systemctl restart nginx
fi
