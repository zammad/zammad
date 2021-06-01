# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FixedTranslation < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    settings_update = [
      {
        'name'        => 'app_version',
        'title'       => nil,
        'description' => 'Only used internally to propagate current web app version to clients.',
      },
      {
        'name'        => 'websocket_port',
        'title'       => 'Websocket port',
        'description' => nil,
      },
      {
        'name'        => 'http_type',
        'title'       => 'HTTP type',
        'description' => 'Define the http protocol of your instance.',
      },
      {
        'name'        => 'storage_provider',
        'title'       => nil,
        'description' => '"Database" stores all attachments in the database (not recommended for storing large amounts of data). "Filesystem" stores the data in the filesystem. You can switch between the modules even on a system that is already in production without any loss of data.',
      },
      {
        'name'        => 'geo_ip_backend',
        'title'       => nil,
        'description' => 'Defines the backend for geo IP lookups. Shows also location of an IP address if an IP address is shown.',
      },
      {
        'name'        => 'geo_calendar_backend',
        'title'       => nil,
        'description' => 'Defines the backend for geo calendar lookups. Used for initial calendar succession.',
      },
      {
        'name'        => 'ui_client_storage',
        'title'       => nil,
        'description' => 'Use client storage to cache data to enhance performance of application.',
      },
      {
        'name'        => 'password_min_size',
        'title'       => 'Minimum length',
        'description' => 'Password needs to have at least a minimal number of characters.',
      },
      {
        'name'        => 'password_need_digit',
        'title'       => nil,
        'description' => 'Password needs to contain at least one digit.',
      },
      {
        'name'        => 'password_max_login_failed',
        'title'       => 'Maximum failed logins',
        'description' => 'Number of failed logins after account will be deactivated.',
      },
      {
        'name'        => 'ticket_hook',
        'title'       => nil,
        'description' => 'The identifier for a ticket, e.g. Ticket#, Call#, MyTicket#. The default is Ticket#.',
      },
      {
        'name'        => 'ticket_hook_divider',
        'title'       => nil,
        'description' => 'The divider between TicketHook and ticket number. E. g. \': \'.',
      },
      {
        'name'        => 'ticket_hook_position',
        'title'       => nil,
        'description' => "The format of the subject.
* **Right** means **Some Subject [Ticket#12345]**
* **Left** means **[Ticket#12345] Some Subject**
* **None** means **Some Subject** (without ticket number). In the last case you should enable *postmaster_follow_up_search_in* to recognize follow-ups based on email headers and/or body.",
      },
      {
        'name'        => 'customer_ticket_create_group_ids',
        'title'       => nil,
        'description' => 'Defines groups for which a customer can create tickets via web interface. "-" means all groups are available.',
      },
      {
        'name'        => 'form_ticket_create',
        'title'       => nil,
        'description' => 'Defines if tickets can be created via web form.',
      },
      {
        'name'        => 'ticket_subject_size',
        'title'       => nil,
        'description' => 'Max. length of the subject in an email reply.',
      },
      {
        'name'        => 'ticket_subject_re',
        'title'       => nil,
        'description' => 'The text at the beginning of the subject in an email reply, e.g. RE, AW, or AS.',
      },
      {
        'name'        => 'ticket_define_email_from',
        'title'       => nil,
        'description' => 'Defines how the From field of emails (sent from answers and email tickets) should look like.',
      },
      {
        'name'        => 'ticket_define_email_from_separator',
        'title'       => nil,
        'description' => 'Defines the separator between the agent\'s real name and the given group email address.',
      },
      {
        'name'        => 'postmaster_max_size',
        'title'       => 'Maximum Email Size',
        'description' => 'Maximum size in MB of emails.',
      },
      {
        'name'        => 'postmaster_follow_up_search_in',
        'title'       => 'Additional follow-up detection',
        'description' => 'By default the follow-up check is done via the subject of an email. With this setting you can add more fields for which the follow-up check will be executed.',
      },
      {
        'name'        => 'send_no_auto_response_reg_exp',
        'title'       => nil,
        'description' => 'If this regex matches, no notification will be sent by the sender.',
      },
      {
        'name'        => 'api_token_access',
        'title'       => nil,
        'description' => 'Enable REST API using tokens (not username/email address and password). Each user needs to create its own access tokens in user profile.',
      },
      {
        'name'        => 'monitoring_token',
        'title'       => nil,
        'description' => 'Token for monitoring.',
      },
      {
        'name'        => 'chat',
        'title'       => nil,
        'description' => 'Enable/disable online chat.',
      },
      {
        'name'        => 'chat_agent_idle_timeout',
        'title'       => nil,
        'description' => 'Idle timeout in seconds until agent is set offline automatically.',
      },
      {
        'name'        => 'models_searchable',
        'title'       => 'Defines searchable models.',
        'description' => 'Defines the searchable models.',
      },
      {
        'name'        => 'default_controller',
        'title'       => nil,
        'description' => 'Defines the default screen.',
      },
      {
        'name'        => 'es_url',
        'title'       => nil,
        'description' => 'Defines endpoint of Elasticsearch.',
      },
      {
        'name'        => 'es_user',
        'title'       => nil,
        'description' => 'Defines HTTP basic auth user of Elasticsearch.',
      },
      {
        'name'        => 'es_password',
        'title'       => 'Elasticsearch Endpoint Password',
        'description' => 'Defines HTTP basic auth password of Elasticsearch.',
      },
      {
        'name'        => 'es_index',
        'title'       => 'Elasticsearch Endpoint Index',
        'description' => 'Defines Elasticsearch index name.',
      },
      {
        'name'        => 'es_attachment_ignore',
        'title'       => 'Elasticsearch Attachment Extensions',
        'description' => 'Defines attachment extensions which will be ignored by Elasticsearch.',
      },
      {
        'name'        => 'es_attachment_max_size_in_mb',
        'title'       => 'Elasticsearch Attachment Size',
        'description' => nil,
      },
      {
        'name'        => 'import_mode',
        'title'       => nil,
        'description' => 'Puts Zammad into import mode (disables some triggers).',
      },
      {
        'name'        => 'import_backend',
        'title'       => nil,
        'description' => 'Set backend which is being used for import.',
      },
      {
        'name'        => 'import_ignore_sla',
        'title'       => nil,
        'description' => 'Ignore escalation/SLA information for import.',
      },
      {
        'name'        => 'import_otrs_endpoint',
        'title'       => nil,
        'description' => 'Defines OTRS endpoint to import users, tickets, states and articles.',
      },
      {
        'name'        => 'import_otrs_endpoint_key',
        'title'       => nil,
        'description' => 'Defines OTRS endpoint authentication key.',
      },
      {
        'name'        => 'import_otrs_user',
        'title'       => 'Import User for HTTP basic authentication',
        'description' => 'Defines HTTP basic authentication user (only if OTRS is protected via HTTP basic auth).',
      },
      {
        'name'        => 'import_zendesk_endpoint_key',
        'title'       => nil,
        'description' => 'Defines Zendesk endpoint authentication key.',
      },
      {
        'name'        => 'import_zendesk_endpoint_username',
        'title'       => nil,
        'description' => 'Defines Zendesk endpoint authentication user.',
      },
      {
        'name'        => 'time_accounting_selector',
        'title'       => nil,
        'description' => 'Enable time accounting for these tickets.',
      },
      {
        'name'        => 'tag_new',
        'title'       => nil,
        'description' => 'Allow users to create new tags.',
      },
      {
        'name'        => 'defaults_calendar_subscriptions_tickets',
        'title'       => nil,
        'description' => 'Defines the default calendar tickets subscription settings.',
      },
      {
        'name'        => 'translator_key',
        'title'       => 'Defines translator identifier.',
        'description' => nil,
      },
      {
        'name'        => '0010_postmaster_filter_trusted',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to remove X-Zammad headers from not trusted sources.',
      },
      {
        'name'        => '0012_postmaster_filter_sender_is_system_address',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to check if email has been created by Zammad itself and will set the article sender.',
      },
      {
        'name'        => '0015_postmaster_filter_identify_sender',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to identify sender user.',
      },
      {
        'name'        => '0020_postmaster_filter_auto_response_check',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to identify auto responses to prevent auto replies from Zammad.',
      },
      {
        'name'        => '0030_postmaster_filter_out_of_office_check',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to identify out-of-office emails for follow-up detection and keeping current ticket state.',
      },
      {
        'name'        => '0100_postmaster_filter_follow_up_check',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to identify follow-ups (based on admin settings).',
      },
      {
        'name'        => '0900_postmaster_filter_bounce_check',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to identify postmaster bounced - to handle it as follow-up of the original ticket.',
      },
      {
        'name'        => '1000_postmaster_filter_database_check',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter for filters managed via admin interface.',
      },
      {
        'name'        => '5000_postmaster_filter_icinga',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to manage Icinga (http://www.icinga.org) emails.',
      },
      {
        'name'        => '5100_postmaster_filter_nagios',
        'title'       => 'Defines postmaster filter.',
        'description' => 'Defines postmaster filter to manage Nagios (http://www.nagios.org) emails.',
      },
      {
        'name'        => 'icinga_integration',
        'title'       => nil,
        'description' => 'Defines if Icinga (http://www.icinga.org) is enabled or not.',
      },
      {
        'name'        => 'icinga_sender',
        'title'       => nil,
        'description' => 'Defines the sender email address of Icinga emails.',
      },
      {
        'name'        => 'icinga_auto_close',
        'title'       => nil,
        'description' => 'Defines if tickets should be closed if service is recovered.',
      },
      {
        'name'        => 'icinga_auto_close_state_id',
        'title'       => nil,
        'description' => 'Defines the state of auto closed tickets.',
      },
      {
        'name'        => 'nagios_integration',
        'title'       => nil,
        'description' => 'Defines if Nagios (http://www.nagios.org) is enabled or not.',
      },
      {
        'name'        => 'nagios_sender',
        'title'       => nil,
        'description' => 'Defines the sender email address of Nagios emails.',
      },
      {
        'name'        => 'nagios_auto_close',
        'title'       => nil,
        'description' => 'Defines if tickets should be closed if service is recovered.',
      },
      {
        'name'        => 'nagios_auto_close_state_id',
        'title'       => nil,
        'description' => 'Defines the state of auto closed tickets.',
      },
      {
        'name'        => '0100_trigger',
        'title'       => 'Defines sync transaction backend.',
        'description' => 'Defines the transaction backend to execute triggers.',
      },
      {
        'name'        => '0100_notification',
        'title'       => 'Defines transaction backend.',
        'description' => 'Defines the transaction backend to send agent notifications.',
      },
      {
        'name'        => '1000_signature_detection',
        'title'       => 'Defines transaction backend.',
        'description' => 'Defines the transaction backend to detect customer signatures in emails.',
      },
      {
        'name'        => '6000_slack_webhook',
        'title'       => 'Defines transaction backend.',
        'description' => 'Defines the transaction backend which posts messages to Slack (http://www.slack.com).',
      },
      {
        'name'        => 'slack_integration',
        'title'       => nil,
        'description' => 'Defines if Slack (http://www.slack.org) is enabled or not.',
      },
      {
        'name'        => 'slack_config',
        'title'       => nil,
        'description' => 'Defines the slack config.',
      },
      {
        'name'        => 'sipgate_integration',
        'title'       => nil,
        'description' => 'Defines if sipgate.io (http://www.sipgate.io) is enabled or not.',
      },
      {
        'name'        => 'sipgate_config',
        'title'       => nil,
        'description' => 'Defines the sipgate.io config.',
      },
      {
        'name'        => 'clearbit_integration',
        'title'       => nil,
        'description' => 'Defines if Clearbit (http://www.clearbit.com) is enabled or not.',
      },
      {
        'name'        => 'clearbit_config',
        'title'       => nil,
        'description' => 'Defines the Clearbit config.',
      },
      {
        'name'        => '9000_clearbit_enrichment',
        'title'       => 'Defines transaction backend.',
        'description' => 'Defines the transaction backend which will enrich customer and organization information from Clearbit (http://www.clearbit.com).',
      },
      {
        'name'        => '9100_cti_caller_id_detection',
        'title'       => 'Defines transaction backend.',
        'description' => 'Defines the transaction backend which detects caller IDs in objects and store them for CTI lookups.',
      },
      {
        'name'        => '9200_karma',
        'title'       => 'Defines transaction backend.',
        'description' => 'Defines the transaction backend which creates the karma score.',
      },
      {
        'name'        => 'karma_levels',
        'title'       => 'Defines karma levels.',
        'description' => 'Defines the karma levels.',
      },
    ]

    settings_update.each do |setting|
      fetched_setting = Setting.find_by(name: setting['name'] )
      next if !fetched_setting

      if setting['title']
        fetched_setting.title = setting['title']
      end

      if setting['description']
        fetched_setting.description = setting['description']
      end

      fetched_setting.save!
    end

    Translation.sync

  end
end
