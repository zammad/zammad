# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require_relative 'boot'

require 'rails/all'
require_relative 'issue_2656_workaround_for_rails_issue_33600'

# Temporary Hack: skip vite build if ENABLE_EXPERIMENTAL_MOBILE_FRONTEND is not set.
# This must be called before ViteRuby is loaded by Bundler.
# TODO: Remove when this switch is not needed any more.
if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] != 'true'
  ENV['VITE_RUBY_SKIP_ASSETS_PRECOMPILE_EXTENSION'] = 'true'
end

# DO NOT REMOVE THIS LINE - see issue #2037
Bundler.setup

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# EmailAddress gem clashes with EmailAddress model.
# https://github.com/afair/email_address#namespace-conflict-resolution
EmailAddressValidator = EmailAddress
Object.send(:remove_const, :EmailAddress)

# Only load gems for asset compilation if they are needed to avoid
#   having unneeded runtime dependencies like NodeJS.
if ArgvHelper.argv.any? { |e| e.start_with? 'assets:' } || Rails.groups.exclude?('production')
  Bundler.load.current_dependencies.select do |dep|
    require dep.name if dep.groups.include?(:assets)
  end
end

module Zammad
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    Rails.autoloaders.each do |autoloader|
      autoloader.ignore            "#{config.root}/app/frontend"
      autoloader.do_not_eager_load "#{config.root}/lib/core_ext"
      autoloader.collapse          "#{config.root}/lib/omniauth"
      autoloader.collapse          "#{config.root}/lib/generators"
      autoloader.inflector.inflect(
        'github_database' => 'GithubDatabase',
        'otrs'            => 'OTRS',
        'db'              => 'DB',
      )
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading

    # the framework and any gems in your application.

    # Custom directories with classes and modules you want to be autoloadable.
    config.add_autoload_paths_to_load_path = false
    config.autoload_paths += %W[#{config.root}/lib]

    # zeitwerk:check will only check preloaded paths. To make sure that also lib/ gets validated,
    #   add it to the eager_load_paths only if zeitwerk:check is running.
    config.eager_load_paths += %W[#{config.root}/lib] if ArgvHelper.argv[0].eql? 'zeitwerk:check'

    config.active_job.queue_adapter = :delayed_job

    config.active_record.use_yaml_unsafe_load = true

    # Use custom logger to log Thread id next to Process pid
    config.log_formatter = ::Logger::Formatter.new

    # REST api path
    config.api_path = '/api/v1'

    # define cache store
    if ENV['MEMCACHE_SERVERS'].present?
      require 'dalli' # Only load this gem when it is really used.
      config.cache_store = [:mem_cache_store, ENV['MEMCACHE_SERVERS'], { expires_in: 7.days }]
    else
      config.cache_store = [:zammad_file_store, Rails.root.join('tmp', "cache_file_store_#{Rails.env}"), { expires_in: 7.days }]
    end

    # define websocket session store
    # The web socket session store will fall back to localhost Redis usage if REDIS_URL is not set.
    # In this case, or if forced via ZAMMAD_WEBSOCKET_SESSION_STORE_FORCE_FS_BACKEND, the FS back end will be used.
    config.websocket_session_store = ENV['REDIS_URL'].present? && ENV['ZAMMAD_WEBSOCKET_SESSION_STORE_FORCE_FS_BACKEND'].blank? ? :redis : :file

    # default preferences by permission
    config.preferences_default_by_permission = {
      'ticket.agent' => {
        notification_config: {
          matrix: {
            create:           {
              criteria: {
                owned_by_me:     true,
                owned_by_nobody: true,
                subscribed:      true,
                no:              false,
              },
              channel:  {
                email:  true,
                online: true,
              }
            },
            update:           {
              criteria: {
                owned_by_me:     true,
                owned_by_nobody: true,
                subscribed:      true,
                no:              false,
              },
              channel:  {
                email:  true,
                online: true,
              }
            },
            reminder_reached: {
              criteria: {
                owned_by_me:     true,
                owned_by_nobody: false,
                subscribed:      false,
                no:              false,
              },
              channel:  {
                email:  true,
                online: true,
              }
            },
            escalation:       {
              criteria: {
                owned_by_me:     true,
                owned_by_nobody: false,
                subscribed:      false,
                no:              false,
              },
              channel:  {
                email:  true,
                online: true,
              }
            }
          }
        }
      }
    }
  end
end
