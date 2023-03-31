# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

source 'https://rubygems.org'

# core - base
ruby '3.1.3'
gem 'rails', '~> 6.1.0'

# TEMPORARY Security updates from Ruby 3.1.4. Can be removed when updating from Ruby 3.1.3 to a higher version.
# See also: https://www.ruby-lang.org/en/news/2023/03/30/ruby-3-1-4-released/
gem 'time', '>= 0.2.2'
gem 'uri', '>= 0.12.1'
# END TEMPORARY

# core - rails additions
gem 'activerecord-import'
gem 'activerecord-session_store'
gem 'bootsnap', require: false
gem 'composite_primary_keys'
gem 'json'

# core - application servers
gem 'puma', '~> 4', group: :puma
gem 'unicorn', group: :unicorn

# core - supported ORMs
gem 'activerecord-nulldb-adapter', group: :nulldb
gem 'mysql2', '0.5.4', group: :mysql # 0.5.5 produced segfaults in CI.
gem 'pg', '~> 1.2.0', group: :postgres

# core - asynchrous task execution
gem 'daemons'
gem 'delayed_job_active_record'

# core - command line interface
gem 'thor'

# core - websocket
gem 'em-websocket'
gem 'eventmachine'
gem 'hiredis', require: false
# version restriction from actioncable-6.1.6.1/lib/action_cable/subscription_adapter/redis.rb
#   - check after rails update
gem 'redis', '>= 3', '< 5', require: false

# core - password security
gem 'argon2'

# core - state machine
gem 'aasm'

# core - authorization
gem 'pundit'

# core - graphql handling
gem 'graphql'
gem 'graphql-batch', require: 'graphql/batch'

# core - image processing
gem 'rszr'

# core - use same timezone data on any host
gem 'tzinfo-data'

# performance - Memcached
gem 'dalli', require: false

# Vite is required by the web server
gem 'vite_rails'

# Only load gems for asset compilation if they are needed to avoid
#   having unneeded runtime dependencies like NodeJS.
group :assets do
  # asset handling - javascript execution for e.g. linux
  gem 'execjs', require: false

  # asset handling - coffee-script
  gem 'coffee-rails', require: false

  # asset handling - frontend templating
  gem 'eco', require: false

  # asset handling - SASS
  gem 'sassc-rails', require: false

  # asset handling - pipeline
  gem 'sprockets', '~> 3.7.2', require: false
  gem 'terser', require: false

  gem 'autoprefixer-rails', require: false
end

# authentication - provider
gem 'doorkeeper'
gem 'oauth2'

# authentication - third party
gem 'omniauth-rails_csrf_protection'

# authentication - third party providers
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-gitlab'
gem 'omniauth-google-oauth2'
gem 'omniauth-linkedin-oauth2'
gem 'omniauth-microsoft-office365'
gem 'omniauth-saml'
gem 'omniauth-twitter'
gem 'omniauth-weibo-oauth2'

# Rate limiting
gem 'rack-attack'

# channels
gem 'gmail_xoauth'
gem 'koala'
gem 'telegram-bot-ruby'
gem 'twitter'

# channels - email additions
gem 'email_address'
gem 'htmlentities'
gem 'mail'
gem 'mime-types'
gem 'rchardet', '>= 1.8.0'

# networking libraries were removed from stdlib in ruby 3.1..
gem 'net-ftp',  require: false
gem 'net-http', require: false
gem 'net-imap', require: false
gem 'net-pop',  require: false
gem 'net-smtp', require: false

# convert from punycode ACE strings to unicode UTF-8 strings and visa versa
gem 'simpleidn'

# feature - business hours
gem 'biz'

# feature - signature diffing
gem 'diffy'

# feature - excel output
gem 'writeexcel', require: false

# feature - csv import/export
gem 'csv', require: false

# feature - device logging
gem 'browser'

# feature - iCal export
gem 'icalendar'
gem 'icalendar-recurrence'

# feature - phone number formatting
gem 'telephone_number'

# feature - SMS
gem 'messagebird-rest'
gem 'twilio-ruby', require: false

# feature - ordering
gem 'acts_as_list'

# integrations
gem 'clearbit', require: false
gem 'net-ldap'
gem 'slack-notifier', require: false
gem 'zendesk_api', require: false

# integrations - exchange
gem 'autodiscover', git: 'https://github.com/zammad-deps/autodiscover', require: false
gem 'viewpoint', require: false

# integrations - S/MIME
gem 'openssl'

# Translation sync
gem 'byk', require: false
gem 'PoParser', require: false

# Gems used only for develop/test and not required
# in production environments by default.
group :development, :test do

  # watch file changes
  gem 'listen'

  # debugging
  gem 'byebug'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'

  # test frameworks
  gem 'minitest-profile', require: false
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rspec-retry'
  gem 'shoulda-matchers'
  gem 'test-unit'

  # for testing Pundit authorisation policies in RSpec
  gem 'pundit-matchers'

  # UI tests w/ Selenium
  gem 'capybara'
  gem 'selenium-webdriver'

  # code QA
  gem 'brakeman', require: false
  gem 'overcommit'
  gem 'rubocop'
  gem 'rubocop-faker'
  gem 'rubocop-graphql'
  gem 'rubocop-inflector'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'

  # generate random test data
  gem 'factory_bot_rails'
  gem 'faker'

  # mock http calls
  gem 'webmock'

  # record and replay TCP/HTTP transactions
  gem 'tcr', require: false
  gem 'vcr', require: false

  # handle deprecations in core and addons
  gem 'deprecation_toolkit'

  # image comparison in tests
  gem 'chunky_png'

  # refresh ENVs in CI environment
  gem 'dotenv', require: false

  # Slack helper for testing
  gem 'slack-ruby-client', require: false
end

# Want to extend Zammad with additional gems?
# ZAMMAD USERS: Specify them in Gemfile.local
#               (That way, you can customize the Gemfile
#               without having your changes overwritten during upgrades.)
# ZAMMAD DEVS:  Consult the internal wiki
#               (or else risk pushing unwanted changes to Gemfile.lock!)
#               https://git.zammad.com/zammad/zammad/wikis/Tips#user-content-customizing-the-gemfile
Dir['Gemfile.local*'].each do |file|
  eval_gemfile file
end
