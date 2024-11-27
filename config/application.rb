# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require_relative 'boot'

require 'rails/all'
require_relative '../lib/zammad/safe_mode'

# DO NOT REMOVE THIS LINE - see issue #2037
Bundler.setup

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Initializers for before the app gets set up.
Pathname(__dir__).glob('pre_initializers/*.rb').each do |file|
  require file
end

module Zammad
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    Rails.autoloaders.each do |autoloader|
      autoloader.ignore            "#{config.root}/app/frontend"
      autoloader.do_not_eager_load "#{config.root}/lib/core_ext"
      autoloader.collapse          "#{config.root}/lib/omniauth"
      autoloader.collapse          "#{config.root}/lib/generators"
      autoloader.inflector.inflect(
        'github_database' => 'GithubDatabase',
        'otrs'            => 'OTRS',
        'db'              => 'DB',
        'pgp'             => 'PGP',
      )
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading

    # the framework and any gems in your application.

    # Custom directories with classes and modules you want to be autoloadable.
    config.add_autoload_paths_to_load_path = false
    # We cannot use 'autoload_lib' as it would also add 'lib/' to eager_load_paths, see #5420.
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
    if ENV['MEMCACHE_SERVERS'].present? && !Zammad::SafeMode.enabled?
      require 'dalli' # Only load this gem when it is really used.
      config.cache_store = [:mem_cache_store, ENV['MEMCACHE_SERVERS'], { expires_in: 7.days }]
    else
      config.cache_store = [:zammad_file_store, Rails.root.join('tmp', "cache_file_store_#{Rails.env}"), { expires_in: 7.days }]
    end

    # define websocket session store
    # The web socket session store will fall back to localhost Redis usage if REDIS_URL is not set.
    # In this case, or if forced via ZAMMAD_WEBSOCKET_SESSION_STORE_FORCE_FS_BACKEND, the FS back end will be used.
    legacy_ws_use_redis = ENV['REDIS_URL'].present? && ENV['ZAMMAD_WEBSOCKET_SESSION_STORE_FORCE_FS_BACKEND'].blank? && !Zammad::SafeMode.enabled?
    config.websocket_session_store = legacy_ws_use_redis ? :redis : :file
  end
end
