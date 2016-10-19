# Installation on Ubuntu 12.04 Server
## With Apache mod_proxy / MySQL

### Prerequisits
* apt-get install curl git-core patch build-essential bison zlib1g-dev libssl-dev libxml2-dev libxml2-dev sqlite3 libsqlite3-dev autotools-dev libxslt1-dev libyaml-0-2 autoconf automake libreadline6-dev libyaml-dev libtool

### Add User
* useradd zammad -m -s /bin/bash
* echo -e "export RAILS_ENV=development" >> /home/zammad/.bashrc
* su zammad
* cd ~

### Install Ruby & Rails
* curl -L https://get.rvm.io | bash -s stable
* source /home/zammad/.rvm/scripts/rvm
* echo "source /home/zammad/.rvm/scripts/rvm" >> /home/zammad/.bashrc
* rvm install ruby
* gem install rails therubyracer

### Apache Config
* vi /etc/apache2/sites-available/zammad

```
<VirtualHost *:80>
    ServerName zammad.example.com
    ServerAdmin yourmail@example.com

    SuexecUserGroup "zammad" "zammad"

    ## don't loose time with IP address lookups
    HostnameLookups Off

    ## needed for named virtual hosts
    UseCanonicalName Off

    ## configures the footer on server-generated documents
    ServerSignature Off

    ProxyRequests Off
    ProxyPreserveHost On

    <Proxy *>
        Order deny,allow
        Allow from localhost
    </Proxy>

    ProxyPass /assets !
    ProxyPass /favicon.ico !
    ProxyPass /robots.txt !
    ProxyPass / http://localhost:3000/

    DocumentRoot "/var/www/zammad/public"

    <Directory />
        Options FollowSymLinks
        AllowOverride None
    </Directory>

    <Directory "/var/www/zammad/public">
        Options FollowSymLinks
        Order allow,deny
        Allow from all
    </Directory>

</VirtualHost>
```

* rm /etc/apache2/sites-enabled/000-default
* ln -s /etc/apache2/sites-available/zammad /etc/apache2/sites-enabled/zammad
* ln -s /etc/apache2/mods-available/proxy.conf /etc/apache2/mods-enabled/proxy.conf
* ln -s /etc/apache2/mods-available/proxy.load /etc/apache2/mods-enabled/proxy.load
* ln -s /etc/apache2/mods-available/proxy_http.load /etc/apache2/mods-enabled/proxy_http.load
* ln -s /etc/apache2/mods-available/suexec.load /etc/apache2/mods-enabled/suexec.load
* service apache2 restart

### Get Zammad
* cd /var/www/zammad
* wget http://zammad.org/zammad-latest.tar.gz
* tar -xzf zammad-latest.tar.gz

### Edit Gemfile
* vi Gemfile
  * uncomment
    * gem 'libv8', '~> 3.11.8'
    * gem 'execjs'
    * gem 'therubyracer'

### Install zammad
* bundle install
* chown -R zammad:zammad /var/www/zammad

### Create Database
* mysql --defaults-file=/etc/mysql/debian.cnf -e "CREATE DATABASE zammad_prod DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci; CREATE USER 'zammad'@'localhost' IDENTIFIED BY 'some_pass'; GRANT ALL PRIVILEGES ON zammad_prod.* TO 'zammad'@'localhost'; FLUSH PRIVILEGES;"
* vi config/database.yml
* su zammad
* cd ~
* rake db:migrate
* rake db:seed

### Start Server
* rake assets:precompile
* puma -p 3000 # application web server
* script/websocket-server.rb start # non blocking websocket server
* script/scheduler.rb start # generate overviews on demand, just send changed data to browser




## Testinstallation for Developers via RVM / SQLite

### Prerequisits
* apt-get install curl git-core patch build-essential bison zlib1g-dev libssl-dev libxml2-dev libxml2-dev sqlite3 libsqlite3-dev autotools-dev libxslt1-dev libyaml-0-2 autoconf automake libreadline6-dev libyaml-dev libtool

### Add User
* useradd zammad -m -s /bin/bash
* echo -e "export RAILS_ENV=development" >> /home/zammad/.bashrc
* su zammad
* cd ~

### Install Ruby & Rails
* curl -L https://get.rvm.io | bash -s stable
* source /home/zammad/.rvm/scripts/rvm
* echo "source /home/zammad/.rvm/scripts/rvm" >> /home/zammad/.bashrc
* rvm install ruby
* gem install rails therubyracer

### Get Zammad
* cd /var/www/zammad
* wget http://zammad.org/zammad-1.0.1.tar.gz
* tar -xzf zammad-1.0.1.tar.gz

### Edit Gemfile
* vi Gemfile
  * uncomment
     * gem 'libv8', '~> 3.11.8'
     * gem 'execjs'
     * gem 'therubyracer'

### Install zammad
* bundle install
* rake db:migrate
* rake db:seed
* rake assets:precompile
* puma -p 3000 # application web server
* script/websocket-server.rb start # non blocking websocket server
* script/scheduler.rb start # generate overviews on demand, just send changed data to browser

