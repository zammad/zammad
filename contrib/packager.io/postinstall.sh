#!/bin/bash
#
# packager.io postinstall script
#

PATH=/opt/zammad/bin:/opt/zammad/vendor/bundle/bin:/sbin:/bin:/usr/sbin:/usr/bin:

ZAMMAD_DIR="/opt/zammad"
DB="zammad_production"
DB_USER="zammad"
MY_CNF="/etc/mysql/debian.cnf"

# check which init system is used
if [ -n "$(which initctl)" ]; then
    INIT_CMD="initctl"
elif [ -n "$(which systemctl)" ]; then
    INIT_CMD="systemctl"
else
    function sysvinit () {
	service $2 $1
    }
    INIT_CMD="sysvinit"
fi

echo "# (Re)creating init scripts"
zammad scale web=1 websocket=1 worker=1

echo "# Stopping Zammad"
${INIT_CMD} stop zammad

# check if database.yml exists
if [ -f ${ZAMMAD_DIR}/config/database.yml ]; then
    # db migration
    echo "# database.yml found. Updating db..."
    zammad run rake db:migrate
else
    echo "# database.yml not found. Creating new db..."

    # create new password
    DB_PASS="$(tr -dc A-Za-z0-9 < /dev/urandom | head -c10)"

    # postgresql
    if [ -n "$(which psql)" ]; then
	echo "installing zammad on postgresql"

	# centos
	if [ -n "$(which postgresql-setup)" ]; then
    	    echo "preparing postgresql server"
    	    postgresql-setup initdb

    	    echo "backuping postgres config"
    	    test -f /var/lib/pgsql/data/pg_hba.conf.bak || cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.bak

    	    echo "allow login via username and password in postgresql"
    	    sed 's/ident/trust/g' < /var/lib/pgsql/data/pg_hba.conf.bak > /var/lib/pgsql/data/pg_hba.conf

    	    echo "restarting postgresql server"
    	    ${INIT_CMD} restart postgresql

    	    echo "create postgresql bootstart"
    	    ${INIT_CMD} enable postgresql.service
	fi

        # create database
        su - postgres -c "createdb -E UTF8 ${DB}"

        # create postgres user
        echo "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASS}';" | su - postgres -c psql 

        # grant privileges
        echo "GRANT ALL PRIVILEGES ON DATABASE \"${DB}\" TO \"${DB_USER}\";" | su - postgres -c psql

        # update configfile
        sed -e "s/.*adapter:.*/  adapter: postgresql/" \
        -e "s/.*username:.*/  username: ${DB_USER}/" \
        -e  "s/.*password:.*/  password: ${DB_PASS}/" \
        -e "s/.*database:.*/  database: ${DB}/" < ${ZAMMAD_DIR}/config/database.yml.dist > ${ZAMMAD_DIR}/config/database.yml

    # mysql / mariadb
    elif [ -n "$(which mysql)" ];then
	echo "installing zammd on mysql"

	if [ -f "${MY_CNF}" ]; then
    	    MYSQL_CREDENTIALS="--defaults-file=${MY_CNF}"
	else
    	    echo -n "Please enter your MySQL root password:"
    	    read -s MYSQL_ROOT_PASS
    	    MYSQL_CREDENTIALS="-u root -p${MYSQL_ROOT_PASS}"
	fi

	echo "creating zammad mysql db"
	mysql ${MYSQL_CREDENTIALS} -e "CREATE DATABASE ${DB} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"

	echo "creating zammad mysql user"
	mysql ${MYSQL_CREDENTIALS} -e "CREATE USER \"${DB_USER}\"@\"${DB_HOST}\" IDENTIFIED BY \"${DB_PASS}\";"

        echo "grant privileges to new mysql user"
	mysql ${MYSQL_CREDENTIALS} -e "GRANT ALL PRIVILEGES ON ${DB}.* TO \"${DB_USER}\"@\"${DB_HOST}\"; FLUSH PRIVILEGES;"

	# update configfile
	sed -e "s/.*adapter:.*/  adapter: mysql2/" \
    	    -e "s/.*username:.*/  username: ${DB_USER}/" \
    	    -e  "s/.*password:.*/  password: ${DB_PASS}/" \
    	    -e "s/.*database:.*/  database: ${DB}/" < ${ZAMMAD_DIR}/config/database.yml.dist > ${ZAMMAD_DIR}/config/database.yml

	# sqlite / no local db
    elif [ -n "$(which sqlite)" ];then
	echo "installing zammad on sqlite"
	echo "in fact this does nothing at the moment. use this to install zammad without a local database. sqlite should only be used in dev environment anyway."
    fi

    # fill database
    zammad run rake db:migrate
    zammad run rake db:seed

fi

echo "# Starting Zammad"
${INIT_CMD} start zammad

# copy nginx config
if [ -n "$(which nginx)" ]; then
    # debian / ubuntu
    if [ -d /etc/nginx/sites-enabled ]; then
	NGINX_CONF="/etc/nginx/sites-enabled/zammad.conf"
	test -f /etc/nginx/sites-available/zammad.conf || cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf /etc/nginx/sites-available/zammad.conf
	test -h ${NGINX_CONF} || ln -s /etc/nginx/sites-available/zammad.conf ${NGINX_CONF}

    # centos / sles
    elif [ -d /etc/nginx/conf.d ]; then
	NGINX_CONF="/etc/nginx/conf.d/zammad.conf"
	test -f ${NGINX_CONF} || cp ${ZAMMAD_DIR}/contrib/nginx/zammad.conf ${NGINX_CONF}
    fi

    echo "# Restarting Nginx"
    ${INIT_CMD} restart nginx
fi

echo -e "\nAdd your FQDN to servername directive in ${NGINX_CONF} and restart nginx if you're not testing localy"
echo -e "or open http://localhost in your browser to start using Zammad.\n"
