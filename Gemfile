source 'https://rubygems.org'

# core - base
ruby '2.4.4'
gem 'rails', '5.1.5'

# core - rails additions
gem 'activerecord-session_store'
gem 'composite_primary_keys'
gem 'json'
gem 'rails-observers'

# core - application servers
gem 'puma', group: :puma
gem 'unicorn', group: :unicorn

# core - supported ORMs
gem 'activerecord-nulldb-adapter', group: :nulldb
gem 'mysql2', group: :mysql
gem 'pg', group: :postgres

# core - asynchrous task execution
gem 'daemons'
gem 'delayed_job_active_record'

# core - websocket
gem 'em-websocket'
gem 'eventmachine'

# core - password security
gem 'argon2'

# performance - Memcached
gem 'dalli'

# asset handling
group :assets do
  # asset handling - coffee-script
  gem 'coffee-rails'
  gem 'coffee-script-source'

  # asset handling - frontend templating
  gem 'eco'

  # asset handling - SASS
  gem 'sass-rails'

  # asset handling - pipeline
  gem 'sprockets'
  gem 'uglifier'
end

gem 'autoprefixer-rails'

# asset handling - javascript execution for e.g. linux
gem 'execjs'
gem 'libv8'
gem 'therubyracer'

# authentication - provider
gem 'doorkeeper'
gem 'oauth2'

# authentication - third party
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-gitlab'
gem 'omniauth-google-oauth2'
gem 'omniauth-linkedin-oauth2'
gem 'omniauth-microsoft-office365'
gem 'omniauth-oauth2'
gem 'omniauth-twitter'
gem 'omniauth-weibo-oauth2'

# channels
gem 'koala'
gem 'telegramAPI'
gem 'twitter'

# channels - email additions
gem 'htmlentities'
gem 'mail', '>= 2.7.1.rc1'
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

# integrations
gem 'clearbit'
gem 'net-ldap'
gem 'slack-notifier'
gem 'zendesk_api'

# integrations - exchange
gem 'autodiscover', git: 'https://github.com/thorsteneckel/autodiscover.git'
gem 'rubyntlm', git: 'https://github.com/wimm/rubyntlm.git'
gem 'viewpoint'

# Gems used only for develop/test and not required
# in production environments by default.
group :development, :test do

  # debugging
  gem 'byebug'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'

  # test frameworks
  gem 'rspec-rails'
  gem 'test-unit'

  # test DB
  gem 'sqlite3'

  # code coverage
  gem 'coveralls', require: false
  gem 'simplecov'
  gem 'simplecov-rcov'

  # UI tests w/ Selenium
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

  # changelog generation
  gem 'github_changelog_generator'

  # Use Factory Bot for generating random test data
  gem 'factory_bot_rails'

  # mock http calls
  gem 'webmock'
end

# Want to extend Zammad with additional gems?
# ZAMMAD USERS: Specify them in Gemfile.local
#               (That way, you can customize the Gemfile
#               without having your changes overwritten during upgrades.)
# ZAMMAD DEVS:  Consult the internal wiki
#               (or else risk pushing unwanted changes to Gemfile.lock!)
#               https://git.znuny.com/zammad/zammad/wikis/Tips#user-content-customizing-the-gemfile
eval_gemfile 'Gemfile.local' if File.exist?('Gemfile.local')
