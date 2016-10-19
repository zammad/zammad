# Installation on Ubuntu 16.04 Server
## With Nginx & MySQL

### Prerequisites
* apt-get install curl git-core patch build-essential bison zlib1g-dev libssl-dev libxml2-dev libxml2-dev sqlite3 libsqlite3-dev autotools-dev libxslt1-dev libyaml-0-2 autoconf automake libreadline6-dev libyaml-dev libtool libgmp-dev libgdbm-dev libncurses5-dev pkg-config libffi-dev libmysqlclient-dev mysql-server nginx
* mysql --defaults-extra-file=/etc/mysql/debian.cnf -e "CREATE USER 'zammad'@'localhost' IDENTIFIED BY 'Your_Pass_Word!'; GRANT ALL PRIVILEGES ON zammad_prod.* TO 'zammad'@'localhost'; FLUSH PRIVILEGES;"
* ln -s /opt/zammad/contrib/nginx/sites-available/zammad.conf /etc/nginx/sites-enabled/zammad.conf

### Add User
* useradd zammad -m -d /opt/zammad -s /bin/bash
* echo "export RAILS_ENV=production" >> /opt/zammad/.bashrc

### Get Zammad
* su zammad
* cd ~
* wget http://ftp.zammad.com/zammad-latest.tar.gz
* tar -xzf zammad-latest.tar.gz

### Install Environnment
* gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
* curl -L https://get.rvm.io | bash -s stable
* source /opt/zammad/.rvm/scripts/rvm
* echo "source /opt/zammad/.rvm/scripts/rvm" >> /opt/zammad/.bashrc
* echo "rvm --default use 2.3.1" >> /opt/zammad/.bashrc
* rvm install 2.3.1
* gem install bundler

### Install Zammad
* bundle install --without test development postgres
* cp config/database.yml.dist config/database.yml
* vi config/database.yml
* rake db:create
* rake db:migrate
* rake db:seed
* rake assets:precompile

### Start Zammad
* rails s -p 3000
* script/websocket-server.rb start
* script/scheduler.rb start
* systemctl restart nginx

