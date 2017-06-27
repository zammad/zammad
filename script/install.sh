#!/bin/bash

USER=zammad
REPOURL=git@github.com:martini/zammad.git
DBNAME=zammad
DBUSER=zammad

function check_requirements() {
    items="git useradd sudo getent curl bash gcc make svn apg"
    for item in $items 
    do
        which $item > /dev/null
        if [ $? -ne 0 ]; then
           echo Please install $item and start this script again.
           exit 1
        fi
    done
}

function check_os()
{
    # Debian
    if [ -f /etc/debian_version ]; then
        OS=Debian
        local MAJOR=$(cut -d. /etc/debian_version -f1)
        if [ $MAJOR -lt 7 ]; then
            echo Please check the supported operating systems
            exit 1
        fi
    fi
}

check_requirements
check_os


#
# @TODO Should the mysql user be created?
# @TODO Install Elasticsearch?
# @TODO Should the script create a VirtualHost or a config file to include for apache/nginx? 
#

#
# Check for zammad user and create if needed
#
id -u "${USER}" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    useradd -c 'user running zammad' -m -s /bin/bash $USER
fi

#
# find the user's homedir and primary group name
#
HOMEDIR=$(getent passwd $USER | cut -d: -f 6)
GROUP=$(id -gn $USER)

cd "${HOMEDIR}"
sudo -u "${USER}" -H git clone $REPOURL zammad
cd zammad
LATEST=$(git tag --list|sort|tail -1)
git checkout tags/"${LATEST}"
chown -R "${USER}":"${GROUP}" .

#
# RVM
#
sudo -u "${USER}" -H bash -c 'curl -sSL https://get.rvm.io | bash -s stable'


#
# install Ruby
#
sudo -u "${USER}" -H bash -l -c 'rvm install 2.1.2'
sudo -u "${USER}" -H bash -l -c 'rvm alias create default 2.1.2'

#
# after rvm requirements
# Installing required packages: gawk, g++, libreadline6-dev, zlib1g-dev, libssl-dev, libyaml-dev, libsqlite3-dev, sqlite3, autoconf, libgdbm-dev, libncurses5-dev, automake, libtool, bison, pkg-config, libffi-dev................


sudo -u "${USER}" -H bash -l -c 'cd ~/zammad && gem install rails --no-ri --no-rdoc'
sudo -u "${USER}" -H bash -l -c 'cd ~/zammad && bundle install --jobs 8'

DBPASS=$(apg -x8|head -1)
echo Password $DBPASS 
mysql -e "GRANT ALL ON ${DBNAME}.* to '${DBUSER}'@'localhost' IDENTIFIED BY '$DBPASS'";
sudo -u $USER -H cp ${HOMEDIR}/zammad/config/database.yml.dist ${HOMEDIR}/zammad/config/database.yml
sudo -u $USER -H sed -i s/some_pass/${DBPASS}/g  ${HOMEDIR}/zammad/config/database.yml
sudo -u $USER -H sed -i s/some_user/${DBUSER}/g  ${HOMEDIR}/zammad/config/database.yml
sudo -u $USER -H sed -i s/zammad_prod/zammad/g  ${HOMEDIR}/zammad/config/database.yml

#
#
#
sudo -u "${USER}" -H bash -l -c 'cd ~/zammad && RAILS_ENV=production rake db:create'
sudo -u "${USER}" -H bash -l -c 'cd ~/zammad && RAILS_ENV=production rake db:migrate'
sudo -u "${USER}" -H bash -l -c 'cd ~/zammad && RAILS_ENV=production rake db:seed'
sudo -u "${USER}" -H bash -l -c 'cd ~/zammad && RAILS_ENV=production rake assets:precompile'

cp "${HOMEDIR}/zammad/script/init.d/zammad /etc/init.d/zammad"
chmod +x /etc/init.d/zammad

if [ "$OS" = "Debian" ]; then
  update-rc.d zammad defaults
fi

