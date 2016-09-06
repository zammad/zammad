class UpdateSettingPermission < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    updates = [
      {
        name: 'maintenance_mode',
        preferences: {
          permission: ['admin.maintenance']
        },
      },
      {
        name: 'maintenance_login',
        preferences: {
          permission: ['admin.maintenance']
        },
      },
      {
        name: 'maintenance_login_message',
        preferences: {
          permission: ['admin.maintenance']
        },
      },
      {
        name: 'product_name',
        preferences: {
          permission: ['admin.branding']
        },
      },
      {
        name: 'product_logo',
        preferences: {
          permission: ['admin.branding']
        },
      },
      {
        name: 'system_id',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'fqdn',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'http_type',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'storage',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'image_backend',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'geo_ip_backend',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'geo_location_backend',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'geo_calendar_backend',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'ui_send_client_stats',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'ui_client_storage',
        preferences: {
          permission: ['admin.system']
        },
      },
      {
        name: 'user_create_account',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'user_lost_password',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_ldap',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_twitter',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_twitter_credentials',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_facebook',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_facebook_credentials',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_google_oauth2',
        preferences: {
          permission: ['admin.maintenance']
        },
      },
      {
        name: 'maintenance_mode',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_google_oauth2_credentials',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_linkedin',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_linkedin_credentials',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_github',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_github_credentials',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_gitlab',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_gitlab_credentials',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_oauth2',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'auth_oauth2_credentials',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'password_min_size',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'password_min_2_lower_2_upper_characters',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'password_need_digit',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'password_max_login_failed',
        preferences: {
          permission: ['admin.security']
        },
      },
      {
        name: 'ticket_hook',
        preferences: {
          permission: ['admin.ticket']
        },
      },
      {
        name: 'ticket_hook_divider',
        preferences: {
          permission: ['admin.ticket']
        },
      },
      {
        name: 'ticket_hook_position',
        preferences: {
          permission: ['admin.ticket']
        },
      },
      {
        name: 'ticket_number',
        preferences: {
          permission: ['admin.ticket']
        },
      },
      {
        name: 'ticket_number_increment',
        preferences: {
          permission: ['admin.ticket']
        },
      },
      {
        name: 'ticket_number_date',
        preferences: {
          permission: ['admin.ticket']
        },
      },
      {
        name: 'customer_ticket_create',
        preferences: {
          permission: ['admin.channel_web']
        },
      },
      {
        name: 'customer_ticket_create_group_ids',
        preferences: {
          permission: ['admin.channel_web']
        },
      },
      {
        name: 'customer_ticket_view',
        preferences: {
          permission: ['admin.channel_web']
        },
      },
      {
        name: 'form_ticket_create',
        preferences: {
          permission: ['admin.channel_formular']
        },
      },
      {
        name: 'ticket_subject_size',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'ticket_subject_re',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'ticket_define_email_from',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'ticket_define_email_from_seperator',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'postmaster_max_size',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'postmaster_follow_up_search_in',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'notification_sender',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'send_no_auto_response_reg_exp',
        preferences: {
          permission: ['admin.channel_email']
        },
      },
      {
        name: 'api_token_access',
        preferences: {
          permission: ['admin.api']
        },
      },
      {
        name: 'api_password_access',
        preferences: {
          permission: ['admin.api']
        },
      },
      {
        name: 'chat',
        preferences: {
          permission: ['admin.channel_chat']
        },
      },
      {
        name: 'chat_agent_idle_timeout',
        preferences: {
          permission: ['admin.channel_chat']
        },
      },
      {
        name: 'tag_new',
        preferences: {
          permission: ['admin.tag']
        },
      },
      {
        name: 'icinga_integration',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'icinga_sender',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'icinga_auto_close',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'icinga_auto_close_state_id',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'nagios_integration',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'nagios_sender',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'nagios_auto_close',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'nagios_auto_close_state_id',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'slack_integration',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'slack_config',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'sipgate_integration',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'sipgate_config',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'clearbit_integration',
        preferences: {
          permission: ['admin.integration']
        },
      },
      {
        name: 'clearbit_config',
        preferences: {
          permission: ['admin.integration']
        },
      },
    ]

    updates.each { |item|
      setting = Setting.find_by(name: item[:name])
      item[:preferences].each { |key, value|
        setting.preferences[key] = value
      }
      setting.save!
    }

  end
end
