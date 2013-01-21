=Installation on Mac OS 10.8 for development

== Prerequisits
* Install xcode, open it -> Xcode menu > Preferences > Downloads -> install command line tools
* curl -L https://get.rvm.io | bash -s stable --ruby
* source /Users/me/.rvm/scripts/rvm
* start new shell -> ruby -v

== Get Zammad
* cd ~/src/
* wget http://zammad.org/zammad-1.0.1.tar.gz
* tar -xzf zammad-1.0.1.tar.gz

== Install Zammad
* cd zammad-1.0.1
* bundle install
* sudo ln -s /usr/local/mysql/lib/libmysqlclient.18.dylib /usr/lib/libmysqlclient.18.dylib # if needed!
* rake db:migrate
* rake db:seed

== Start Zammad
* rails server # rails web server
* ruby script/websocket-server.rb # non blocking websocket server
* rails runner 'Session.jobs' # generate overviews on demand, just send changed data to browser

== Start init page
* http://localhost:3000/#getting_started
