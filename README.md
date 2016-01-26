[![build status](https://git.znuny.com/ci/projects/508/status.png?ref=develop)](https://git.znuny.com/ci/projects/508/status.png?ref=develop)

Welcome to Zammad
=================

Zammad is a web based open source helpdesk/ticket system with many features
to manage customer telephone calls and e-mails. It is distributed under the
GNU AFFERO General Public License (AGPL) and tested on Linux, Solaris, AIX,
FreeBSD, OpenBSD and Mac OS 10.x. Do you receive many e-mails and
want to answer them with a team of agents? You're going to love Zammad!


Getting Started
---------------

1. Install Zammad on your system

```
     root@shell> cd /opt/
     root@shell> tar -xzf zammad-1.0.1.tar.gz
     root@shell> useradd zammad
     zammad@shell> su - zammad
```

2. Install all dependencies

```
     zammad@shell> cd zammad
     zammad@shell> gem install rails
     zammad@shell> vi Gemfile # enable libv8, execjs and therubyracer if needed!
     zammad@shell> bundle install
```

3. Configure your databases

```
     zammad@shell> cp config/database.yml.dist config/database.yml
     zammad@shell> vi config/database.yml
```

4. Initialize your database

```
     zammad@shell> export RAILS_ENV=production
     zammad@shell> rake db:create
     zammad@shell> rake db:migrate
     zammad@shell> rake db:seed
```

5. Change directory to zammad</tt> (if needed) and start the web server:

```
     zammad@shell> rake assets:precompile
     zammad@shell> puma -p 3000 # application web server
     zammad@shell> script/websocket-server.rb start # non blocking websocket server
     zammad@shell> script/scheduler.rb start # generate overviews on demand, just send changed data to browser
```

6. Go to http://localhost:3000/#getting_started and you'll see:
       "Welcome to Zammad!", there you need to create your admin
       user and you need to invite other agents.

* The Getting Started Guide: http://guides.zammad.org/getting_started.html

