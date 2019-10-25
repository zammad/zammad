require_relative 'boot'

require 'rails/all'
require_relative 'issue_2656_workaround_for_rails_issue_33600'

# DO NOT REMOVE THIS LINE - see issue #2037
Bundler.setup

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Zammad
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W[#{config.root}/lib]
    config.eager_load_paths += %W[#{config.root}/lib]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
    config.active_record.observers =
      'observer::_session',
      'observer::_ticket::_close_time',
      'observer::_ticket::_last_owner_update',
      'observer::_ticket::_user_ticket_counter',
      'observer::_ticket::_article_changes',
      'observer::_ticket::_article::_fillup_from_origin_by_id',
      'observer::_ticket::_article::_fillup_from_general',
      'observer::_ticket::_article::_fillup_from_email',
      'observer::_ticket::_article::_communicate_email',
      'observer::_ticket::_article::_communicate_facebook',
      'observer::_ticket::_article::_communicate_sms',
      'observer::_ticket::_article::_communicate_twitter',
      'observer::_ticket::_article::_communicate_telegram',
      'observer::_ticket::_reset_new_state',
      'observer::_ticket::_ref_object_touch',
      'observer::_ticket::_online_notification_seen',
      'observer::_ticket::_stats_reopen',
      'observer::_ticket::_escalation_update',
      'observer::_tag::_ticket_history',
      'observer::_user::_ref_object_touch',
      'observer::_user::_ticket_organization',
      'observer::_user::_geo',
      'observer::_organization::_ref_object_touch',
      'observer::_sla::_ticket_rebuild_escalation',
      'observer::_transaction'

    config.active_job.queue_adapter = :delayed_job

    # Use custom logger to log Thread id next to Process pid
    config.log_formatter = ::Logger::Formatter.new

    # REST api path
    config.api_path = '/api/v1'

    # define cache store
    config.cache_store = :file_store, Rails.root.join('tmp', "cache_file_store_#{Rails.env}")

    # default preferences by permission
    config.preferences_default_by_permission = {
      'ticket.agent' => {
        notification_config: {
          matrix: {
            create:           {
              criteria: {
                owned_by_me:     true,
                owned_by_nobody: true,
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
