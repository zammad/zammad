Installation on Mac OS 10.8 for development
===========================================

Prerequisites
------------
* Install Xcode from the App Store, open it -> Xcode menu > Preferences > Downloads -> install command line tools

````shell
    curl -L https://get.rvm.io | bash -s stable --ruby
    source ~/.rvm/scripts/rvm
````
* start new shell -> ruby -v

Get Zammad
----------

````shell
    test -d ~/zammad/ || mkdir ~/zammad 
    cd ~/zammad/
    curl -L -O http://zammad.org/zammad-latest.tar.bz2 | tar -xj
````

Install Zammad
--------------

````shell
    cd zammad-latest
    bundle install
    sudo ln -s /usr/local/mysql/lib/libmysqlclient.18.dylib /usr/lib/libmysqlclient.18.dylib # if needed!
    rake db:create
    rake db:migrate
    rake db:seed
````

Start Zammad
------------

````shell
    rails server # rails web server
    ruby script/websocket-server.rb # non blocking websocket server
    rails runner 'Session.jobs' # generate overviews on demand, just send changed data to browser
````

Start init page
---------------
* http://localhost:3000/#getting_started
