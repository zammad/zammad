#!/bin/bash
#
# packager.io postinstall script
#

set -ex

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

ZAMMAD_DIR="/opt/zammad"
DB="zammad"
DB_USER="zammad"
MY_CNF="/etc/mysql/debian.cnf"

# check which init system is used
if [ -n "$(which systemctl 2> /dev/null)" ]; then
    INIT_CMD="systemctl"
elif [ -n "$(which initctl 2> /dev/null)" ]; then
    INIT_CMD="initctl"
else
    function sysvinit () {
        service $2 $1
    }
    INIT_CMD="sysvinit"
fi

echo "# (Re)creating init scripts"
zammad scale web=1 websocket=1 worker=1

echo "# Enabling Zammad on boot"
${INIT_CMD} enable zammad

echo "# Stopping Zammad"
${INIT_CMD} stop zammad

# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/config/database.yml ]; then
    # db migration
    echo "# database.yml found. Updating db..."
    zammad run rake db:migrate
else
    echo "# database.yml not found. Creating db..."

    # create new password
    DB_PASS="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c10)"

    # postgresql
    if [ -n "$(which psql 2> /dev/null)" ]; then
        echo "# Installing zammad on postgresql"

        # centos
        if [ -n "$(which postgresql-setup 2> /dev/null)" ]; then
            echo "# Preparing postgresql server"
            postgresql-setup initdb

            #echo "# Backuping postgres config"
            #test -f /var/lib/pgsql/data/pg_hba.conf.bak || cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak

            #echo "# Allow login via username and password in postgresql"
            #sed 's/ident/trust/g' < /var/lib/pgsql/data/pg_hba.conf.bak > /var/lib/pgsql/data/pg_hba.conf
        fi

        # centos / ubuntu / sles
        echo "# Creating postgresql bootstart"
        ${INIT_CMD} enable postgresql.service

        echo "# Restarting postgresql server"
        ${INIT_CMD} restart postgresql

        echo "# Creating zammad postgresql user"
        echo "CREATE USER \"${DB_USER}\";" | su - postgres -c psql

        echo "# Creating zammad postgresql db"
        su - postgres -c "createdb -E UTF8 ${DB} -O \"${DB_USER}\""

        echo "# Grant privileges to new postgresql user"
        echo "GRANT ALL PRIVILEGES ON DATABASE \"${DB}\" TO \"${DB_USER}\";" | su - postgres -c psql

        echo "# Updating database.yml"
        sed -e "s/.*adapter:.*/  adapter: postgresql/" \
            -e "s/.*username:.*/  username: ${DB_USER}/" \
            -e "s/.*database:.*/  database: ${DB}/" < ${ZAMMAD_DIR}/config/database.yml.pkgr > ${ZAMMAD_DIR}/config/database.yml

    # mysql / mariadb
    elif [ -n "$(which mysql 2> /dev/null)" ];then
        echo "# Installing zammad on mysql"

        if [ -f "${MY_CNF}" ]; then
            MYSQL_CREDENTIALS="--defaults-file=${MY_CNF}"
        else
            echo -n "Please enter your MySQL root password:"
            read -s MYSQL_ROOT_PASS
            MYSQL_CREDENTIALS="-u root -p${MYSQL_ROOT_PASS}"
        fi

        echo "# Creating zammad mysql db"
        mysql ${MYSQL_CREDENTIALS} -e "CREATE DATABASE ${DB} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"

        echo "# Creating zammad mysql user"
        mysql ${MYSQL_CREDENTIALS} -e "CREATE USER \"${DB_USER}\"@\"${DB_HOST}\" IDENTIFIED BY \"${DB_PASS}\";"

        echo "# Grant privileges to new mysql user"
        mysql ${MYSQL_CREDENTIALS} -e "GRANT ALL PRIVILEGES ON ${DB}.* TO \"${DB_USER}\"@\"${DB_HOST}\"; FLUSH PRIVILEGES;"

        echo "# Updating database.yml"
        sed -e "s/.*adapter:.*/  adapter: mysql2/" \
            -e "s/.*username:.*/  username: ${DB_USER}/" \
            -e  "s/.*password:.*/  password: ${DB_PASS}/" \
            -e "s/.*database:.*/  database: ${DB}/" < ${ZAMMAD_DIR}/config/database.yml.dist > ${ZAMMAD_DIR}/config/database.yml

    # sqlite / no local db
    elif [ -n "$(which sqlite 2> /dev/null)" ];then
        echo "# Installing zammad on sqlite"
        echo "# In fact this does nothing at the moment. use this to install zammad without a local database. sqlite should only be used in dev environment anyway."
    fi

    # fill database
    zammad run rake db:migrate
    zammad run rake db:seed

fi

echo "# Starting Zammad"
${INIT_CMD} start zammad

# on centos, allow nginx to connect to application server
if [ -n "$(which setsebool 2> /dev/null)" ]; then
    echo "# Adding SE Linux rules"
    setsebool httpd_can_network_connect on -P
fi

# on centos, open port 80 and 443
if [ -n "$(which firewall-cmd 2> /dev/null)" ]; then
    echo "# Adding firewall rules"
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    firewall-cmd --reload
fi

# copy webserver config
if [ -n "$(which apache2 2> /dev/null)" ] || [ -n "$(which httpd 2> /dev/null)" ] || [ -n "$(which nginx 2> /dev/null)" ] ; then

    # Nginx
    # debian / ubuntu
    if [ -d /etc/nginx/sites-enabled ]; then
        WEBSERVER_CONF="/etc/nginx/sites-enabled/zammad.conf"
        WEBSERVER_CMD="nginx"
        test -f /etc/nginx/sites-available/zammad.conf || cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf /etc/nginx/sites-available/zammad.conf
        test -h ${WEBSERVER_CONF} || ln -s /etc/nginx/sites-available/zammad.conf ${WEBSERVER_CONF}

    # centos
    elif [ -d /etc/nginx/conf.d ]; then
        WEBSERVER_CONF="/etc/nginx/conf.d/zammad.conf"
        WEBSERVER_CMD="nginx"
        test -f ${WEBSERVER_CONF} || cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf ${WEBSERVER_CONF}

    # sles
    elif [ -d /etc/YaST2 ]; then
        WEBSERVER_CONF="/etc/nginx/vhosts.d/zammad.conf"
        WEBSERVER_CMD="nginx"
        test -d /etc/nginx/vhosts.d || mkdir -p /etc/nginx/vhosts.d
        test -f ${WEBSERVER_CONF} || cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf ${WEBSERVER_CONF}

    # Apache2
    # debian / ubuntu
    elif [ -d /etc/apache2/sites-enabled ]; then
        WEBSERVER_CONF="/etc/apache2/sites-enabled/zammad.conf"
        WEBSERVER_CMD="apache2"
        test -f /etc/apache2/sites-available/zammad.conf || cp ${ZAMMAD_DIR}/contrib/apache2/zammad.conf /etc/apache2/sites-available/zammad.conf
        test -h ${WEBSERVER_CONF} || ln -s /etc/apache2/sites-available/zammad.conf ${WEBSERVER_CONF}

        echo "# Activating Apache2 modules"
        a2enmod proxy
        a2enmod proxy_http
        a2enmod proxy_wstunnel

    # sles
    elif [ -d /etc/apache2/vhosts.d ]; then
        WEBSERVER_CONF="/etc/apache2/vhosts.d/zammad.conf"
        WEBSERVER_CMD="apache2"
        test -f ${WEBSERVER_CONF} || cp ${ZAMMAD_DIR}/contrib/apache2/zammad.conf ${WEBSERVER_CONF}

        echo "# Activating Apache2 modules"
        a2enmod proxy
        a2enmod proxy_http
        a2enmod proxy_wstunnel

    # centos
    elif [ -d /etc/httpd/conf.d ]; then
        WEBSERVER_CONF="/etc/httpd/conf.d/zammad.conf"
        WEBSERVER_CMD="httpd"
        test -f ${WEBSERVER_CONF} || cp ${ZAMMAD_DIR}/contrib/apache2/zammad.conf ${WEBSERVER_CONF}
    fi

    echo "# Creating webserver bootstart"
    ${INIT_CMD} enable ${WEBSERVER_CMD}

    echo "# Restarting webserver ${WEBSERVER_CMD}"
    ${INIT_CMD} restart ${WEBSERVER_CMD}

    echo -e "####################################################################################"
    echo -e "\nAdd your FQDN to servername directive in ${WEBSERVER_CONF}"
    echo -e "and restart your webserver if you're not testing localy"
    echo -e "or open http://localhost in your browser to start using Zammad.\n"
    echo -e "####################################################################################"
else
    echo -e "####################################################################################"
    echo -e "\nOpen http://localhost:3000 in your browser to start using Zammad.\n"
    echo -e "####################################################################################"
fi
