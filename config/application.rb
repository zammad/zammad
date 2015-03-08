require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Zammad
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers =
      'observer::_session',
      'observer::_ticket::_first_response',
      'observer::_ticket::_last_contact',
      'observer::_ticket::_close_time',
      'observer::_ticket::_user_ticket_counter',
      'observer::_ticket::_article_counter',
      'observer::_ticket::_article_sender_type',
      'observer::_ticket::_article::_fillup_from_general',
      'observer::_ticket::_article::_fillup_from_email',
      'observer::_ticket::_article::_communicate_email',
      'observer::_ticket::_article::_communicate_facebook',
      'observer::_ticket::_article::_communicate_twitter',
      'observer::_ticket::_notification',
      'observer::_ticket::_reset_new_state',
      'observer::_ticket::_escalation_calculation',
      'observer::_ticket::_ref_object_touch',
      'observer::_tag::_ticket_history',
      'observer::_user::_ref_object_touch',
      'observer::_user::_geo',
      'observer::_organization::_ref_object_touch'


    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # REST api path
    config.api_path = '/api/v1'

  end
end