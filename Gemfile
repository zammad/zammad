# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

source 'https://rubygems.org'

# core - base
ruby '2.6.6'
gem 'rails', '5.2.4.6'

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
gem 'mysql2', '0.4.10', group: :mysql
gem 'pg', '0.21.0', group: :postgres

# core - asynchrous task execution
gem 'daemons'
gem 'delayed_job_active_record'

# core - websocket
gem 'em-websocket'
gem 'eventmachine'

# core - password security
gem 'argon2'

# core - state machine
gem 'aasm'

# core - authorization
gem 'pundit'

# core - image processing
gem 'rszr', '0.5.2'

# performance - Memcached
gem 'dalli'

# asset handling - coffee-script
gem 'coffee-rails'
gem 'coffee-script-source'

# asset handling - frontend templating
gem 'eco'

# asset handling - SASS
gem 'sassc-rails'

# asset handling - pipeline
gem 'sprockets', '~> 3.7.2'
gem 'uglifier'

gem 'autoprefixer-rails'

# asset handling - javascript execution for e.g. linux
gem 'execjs'

# mini_racer can be omitted on systems where node.js is available via
#   `bundle install --without mini_racer`.
group :mini_racer do
  gem 'libv8'
  gem 'mini_racer'
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
gem 'twitter', git: 'https://github.com/sferik/twitter.git'

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
gem 'writeexcel'

# feature - device logging
gem 'browser'

# feature - iCal export
gem 'icalendar'
gem 'icalendar-recurrence'

# feature - phone number formatting
gem 'telephone_number'

# feature - SMS
gem 'twilio-ruby'

# feature - ordering
gem 'acts_as_list'

# integrations
gem 'clearbit'
gem 'net-ldap'
gem 'slack-notifier'
gem 'zendesk_api'

# integrations - exchange
gem 'autodiscover', git: 'https://github.com/zammad-deps/autodiscover'
gem 'rubyntlm', git: 'https://github.com/wimm/rubyntlm'
gem 'viewpoint'

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
  gem 'coffeelint'
  gem 'pre-commit'
  gem 'rubocop'
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
  gem 'tcr', git: 'https://github.com/zammad-deps/tcr'
  gem 'vcr'

  # handle deprecations in core and addons
  gem 'deprecation_toolkit'

  # image comparison in tests
  gem 'chunky_png'

  # refresh ENVs in CI environment
  gem 'dotenv', require: false
end

# Want to extend Zammad with additional gems?
# ZAMMAD USERS: Specify them in Gemfile.local
#               (That way, you can customize the Gemfile
#               without having your changes overwritten during upgrades.)
# ZAMMAD DEVS:  Consult the internal wiki
#               (or else risk pushing unwanted changes to Gemfile.lock!)
#               https://git.znuny.com/zammad/zammad/wikis/Tips#user-content-customizing-the-gemfile
eval_gemfile 'Gemfile.local' if File.exist?('Gemfile.local')
