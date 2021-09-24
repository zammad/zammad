# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

source 'https://rubygems.org'

# core - base
ruby '2.7.4'
gem 'rails', '~> 6.0'

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
gem 'mysql2', group: :mysql
gem 'pg', '0.21.0', group: :postgres

# core - asynchrous task execution
gem 'daemons'
gem 'delayed_job_active_record'

# core - websocket
gem 'em-websocket'
gem 'eventmachine'
gem 'hiredis', require: false
gem 'redis', require: false

# core - password security
gem 'argon2'

# core - state machine
gem 'aasm'

# core - authorization
gem 'pundit'

# core - image processing
gem 'rszr', '0.5.2'

# performance - Memcached
gem 'dalli', require: false

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
  gem 'uglifier', require: false

  gem 'autoprefixer-rails', require: false
end

# Don't use mini_racer any more for asset compilation.
#   Instead, use an external node.js binary.
group :mini_racer, optional: true do
  gem 'libv8'
  gem 'mini_racer', '0.2.9' # Newer versions require libv8-node instead which does not compile on older platforms.
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

# channels
gem 'gmail_xoauth'
gem 'koala'
gem 'telegramAPI'
gem 'twitter'

# channels - email additions
gem 'htmlentities'
gem 'mail', git: 'https://github.com/zammad-deps/mail', branch: '2-7-stable'
gem 'mime-types'
gem 'rchardet', '>= 1.8.0'
gem 'valid_email2'

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

# Gems used only for develop/test and not required
# in production environments by default.
group :development, :test do

  # app boottime improvement
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-commands-testunit'

  # debugging
  gem 'byebug'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'

  # test frameworks
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'test-unit'

  # for testing Pundit authorisation policies in RSpec
  gem 'pundit-matchers'

  # code coverage
  gem 'coveralls', require: false
  gem 'simplecov'
  gem 'simplecov-rcov'

  # UI tests w/ Selenium
  gem 'capybara'
  gem 'selenium-webdriver'

  # livereload on template changes (html, js, css)
  gem 'guard',             require: false
  gem 'guard-livereload',  require: false
  gem 'rack-livereload',   require: false
  gem 'rb-fsevent',        require: false

  # auto symlinking
  gem 'guard-symlink', require: false

  # code QA
  gem 'brakeman', require: false
  gem 'coffeelint'
  gem 'overcommit'
  gem 'rubocop'
  gem 'rubocop-faker'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'

  # changelog generation
  gem 'github_changelog_generator'

  # generate random test data
  gem 'factory_bot_rails'
  gem 'faker'

  # mock http calls
  gem 'webmock'

  # record and replay TCP/HTTP transactions
  gem 'tcr'
  gem 'vcr'

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
#               https://git.znuny.com/zammad/zammad/wikis/Tips#user-content-customizing-the-gemfile
eval_gemfile 'Gemfile.local' if File.exist?('Gemfile.local')
