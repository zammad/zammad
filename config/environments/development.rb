Zammad::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Do not compress assets
  config.assets.compress = false

  # Deliver all in one application.(js|css) file
  #config.assets.debug = false
  # Expands the lines which load the assets
  config.assets.debug = true

  # Automatically inject JavaScript needed for LiveReload
  config.middleware.use(
    Rack::LiveReload,
    min_delay: 500,    # default 1000
    max_delay: 10_000, # default 60_000
    live_reload_port: 35_738,
    source: :vendored
  )

  # define cache store
  config.cache_store = :file_store, 'tmp/cache_file_store_development'

  # format log
  config.log_formatter = Logger::Formatter.new
end
