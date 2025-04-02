# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

source 'https://rubygems.org'

# core - base
ruby '3.2.8'
gem 'rails', '~> 7.2.0'

# core - rails additions
gem 'activerecord-import'
gem 'activerecord-session_store'
gem 'bootsnap', require: false
gem 'json'
gem 'parallel'

# core - application servers
gem 'puma', group: :puma

# core - supported ORMs
gem 'mysql2', group: :mysql
gem 'pg', '~> 1.5', '>= 1.5.4', group: :postgres

# core - asynchrous task execution
gem 'daemons'
gem 'delayed_job_active_record'

# core - command line interface
gem 'thor'

# core - websocket
gem 'em-websocket'
gem 'eventmachine'
gem 'hiredis'
# version restriction from actioncable-6.1.6.1/lib/action_cable/subscription_adapter/redis.rb
#   - check after rails update
gem 'redis', '>= 3', '< 5'

# core - password security
gem 'argon2'

# core - state machine
gem 'aasm'

# core - authorization
gem 'pundit'

# core - graphql handling
gem 'graphql'
gem 'graphql-batch', require: 'graphql/batch'
gem 'graphql-fragment_cache'

# core - image processing
gem 'rszr'

# core - use same timezone data on any host
gem 'tzinfo-data'

# performance - Memcached
gem 'dalli', require: false

# Vite is required by the web server
gem 'vite_rails'

# asset handling - config.assets for pipeline
gem 'sprockets-rails'

# Workaround
# Explicitly specify nokogiri, even though it is an internal Rails dependency
#   to work around issues with precompiled versions not running on RHEL 8 any more.
# See https://github.com/sparklemotion/nokogiri/issues/3399.
# Consider removing this again after CentOS 8 support was dropped.
gem 'nokogiri', force_ruby_platform: true

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
  # We cannot use sassc-rails, as it can lead to crashes on modern platforms like CentOS 9.
  # See https://jcmaciel.com/apple-silicon-ruby-on-rails-crash-segfault-sassc/
  #     https://github.com/sass/sassc-ruby/issues/197
  # Pin to v5 which does not use sassc internally.
  gem 'sass-rails', '~> 5', require: false

  # asset handling - pipeline
  gem 'sprockets', '~> 3.7.2', require: false
  gem 'terser', require: false

  gem 'autoprefixer-rails', require: false
end

# authentication - provider
gem 'doorkeeper'
gem 'oauth2'

# authentication - two factor
gem 'rotp', require: false
gem 'webauthn', require: false

# authentication - third party
gem 'omniauth-rails_csrf_protection'

# authentication - third party providers
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-gitlab'
gem 'omniauth-google-oauth2'
gem 'omniauth-linkedin-oauth2'
gem 'omniauth-microsoft-office365'
gem 'omniauth_openid_connect'
gem 'omniauth-saml'
gem 'omniauth-twitter'
gem 'omniauth-weibo-oauth2', git: 'https://github.com/zammad-deps/omniauth-weibo-oauth2', branch: 'unpin-dependencies'

# Rate limiting
gem 'rack-attack'

# channels
gem 'koala'
gem 'telegram-bot-ruby'
gem 'twitter', '~> 7'
gem 'whatsapp_sdk'

# channels - email additions
gem 'email_address'
gem 'htmlentities'
gem 'mail'
gem 'mime-types'
gem 'rchardet', '>= 1.8.0'

# networking libraries were removed from stdlib in ruby 3.1..
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
gem 'write_xlsx', require: false

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

# Simple storage
gem 'aws-sdk-s3', require: false

# Debugging and profiling
gem 'byebug'
gem 'pry-byebug'
gem 'pry-rails'
gem 'pry-remote'
gem 'pry-rescue'
gem 'pry-stack_explorer'
gem 'pry-theme'

# monitoring / system report
gem 'macaddr'

# watch file changes (also relevant for graphql generation in context of CDs)
gem 'listen'

# language detection
gem 'cld'

# CLDR wrapper for i18n and l10n
gem 'twitter_cldr'

# Gems used only for develop/test and not required
# in production environments by default.
group :development, :test do

  # test frameworks
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
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-faker'
  gem 'rubocop-graphql'
  gem 'rubocop-inflector'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'

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

  # Slack helper for testing
  gem 'slack-ruby-client', require: false

  # self-signed localhost certificates for puma / capybara
  gem 'localhost'

  # Keycloak admin tool for setting up SAML auth tests
  gem 'ruby-keycloak-admin'

  # Debugging and profiling
  gem 'pry-doc' # This gem is very large, so don't include it in production.
end

# To permanently extend Zammad with additional gems, you can specify them in Gemfile.local.
Dir['Gemfile.local*'].each do |file|
  eval_gemfile file
end
