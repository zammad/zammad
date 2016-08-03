source 'https://rubygems.org'

ruby '2.3.1'

gem 'rails', '4.2.7'
gem 'rails-observers'
gem 'activerecord-session_store'

# Bundle edge Rails instead:
#gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'json'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails' #, github: 'rails/sass-rails'
  gem 'coffee-rails'
  gem 'coffee-script-source'

  gem 'sprockets'

  gem 'uglifier'
  gem 'eco'
end

gem 'autoprefixer-rails'

gem 'oauth2'
gem 'doorkeeper'

gem 'omniauth'
gem 'omniauth-oauth2'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-gitlab'
gem 'omniauth-google-oauth2'
gem 'omniauth-linkedin-oauth2'
gem 'omniauth-twitter'

gem 'twitter'
gem 'koala'
gem 'mail'
gem 'email_verifier'
gem 'htmlentities'

gem 'mime-types'

gem 'biz'

gem 'delayed_job_active_record'
gem 'daemons'

gem 'simple-rss'

# e. g. on linux we need a javascript execution
gem 'libv8'
gem 'execjs'
gem 'therubyracer'

# Include database gems for the adapters found in the database
# configuration file, thanks to redmine, taken from https://github.com/redmine/redmine/blob/master/Gemfile
require 'erb'
require 'yaml'
database_file = File.join(File.dirname(__FILE__), 'config/database.yml')
if File.exist?(database_file)
  database_config = YAML.load(ERB.new(IO.read(database_file)).result)
  adapters = database_config.values.map { |c| c['adapter'] }.compact.uniq
  if adapters.any?
    adapters.each do |adapter|
      case adapter
      when 'mysql2'
        gem 'mysql2', '~> 0.3.20'
      when /postgresql/
        gem 'pg'
      when /sqlite3/
        gem 'sqlite3'
      else
        warn("Unknown database adapter `#{adapter}` found in config/database.yml, use Gemfile.local to load your own database gems")
      end
    end
  else
    warn('No adapter found in config/database.yml, please configure it first')
  end
else
  warn('Please configure your config/database.yml first')
end

gem 'net-ldap'

gem 'writeexcel'
gem 'icalendar'
gem 'browser'
gem 'phony'

# integrations
gem 'slack-notifier'
gem 'clearbit'
gem 'zendesk_api'

# event machine
gem 'eventmachine'
gem 'em-websocket'

gem 'diffy'

# Gems used only for develop/test and not required
# in production environments by default.
group :development, :test do

  gem 'test-unit'
  gem 'spring'
  gem 'sqlite3'

  # code coverage
  gem 'simplecov'
  gem 'simplecov-rcov'

  # UI tests w/ Selenium
  gem 'selenium-webdriver'

  # livereload on template changes (html, js, css)
  gem 'guard',             require: false
  gem 'guard-livereload',  require: false
  gem 'rack-livereload'
  gem 'rb-fsevent',        require: false

  # code QA
  gem 'pre-commit'
  gem 'rubocop'
  gem 'coffeelint'

end

gem 'puma'

# load onw gem's
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local')
if File.exist?(local_gemfile)
  eval_gemfile local_gemfile
end
