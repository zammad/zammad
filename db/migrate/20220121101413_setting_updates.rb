# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class SettingUpdates < ActiveRecord::Migration[6.0]
  def change # rubocop:disable Metrics/AbcSize

    return if !Setting.exists?(name: 'system_init_done')

    settings_update = [
      {
        title:       __('2 lower case and 2 upper case characters'),
        name:        'password_min_2_lower_2_upper_characters',
        description: __('Password needs to contain 2 lower case and 2 upper case characters.'),
      },
      {
        title:       __('User email for multiple users'),
        name:        'user_email_multiple_use',
        description: __('Allow using one email address for multiple users.'),
      },
      {
        title:       __('sipgate.io alternative FQDN'),
        name:        'sipgate_alternative_fqdn',
        description: __('Alternative FQDN for callbacks if you operate Zammad in an internal network.'),
      },
      {
        title: __('Auto Assignment'),
        name:  'ticket_auto_assignment',
      },
      {
        title:       __('BCC address for all outgoing emails'),
        name:        'system_bcc',
        description: __('To archive all outgoing emails from Zammad to external, you can store a BCC email address here.'),
      },
      {
        title:       __('Additional follow-up detection'),
        name:        'postmaster_follow_up_search_in',
        description: __('By default, the follow-up check is done via the subject of an email. This setting lets you add more fields for which the follow-up check will be executed.'),
      },
      {
        title:       __('Note - default visibility'),
        name:        'ui_ticket_zoom_article_note_new_internal',
        description: __('Defines the default visibility for new notes.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '0014_postmaster_filter_own_notification_loop_detection',
        description: __('Defines postmaster filter to check if the email is a self-created notification email, then ignore it to prevent email loops.'),
      },
      {
        title:       __('HTTP type'),
        name:        'http_type',
        description: __('Defines the HTTP protocol of your instance.'),
      },
      {
        title: __('Defines the timeframe during which a self-created note can be deleted.'),
        name:  'ui_ticket_zoom_article_delete_timeframe',
      },
      {
        title:       __('Import Endpoint'),
        name:        'import_freshdesk_endpoint',
        description: __('Defines a Freshdesk endpoint to import users, tickets, states, and articles.'),
      },
      {
        title:       __('Import Endpoint'),
        name:        'import_kayako_endpoint',
        description: __('Defines a Kayako endpoint to import users, tickets, states, and articles.'),
      },
      {
        title:       __('Import Endpoint'),
        name:        'import_otrs_endpoint',
        description: __('Defines an OTRS endpoint to import users, tickets, states, and articles.'),
      },
      {
        title:       __('Import Endpoint'),
        name:        'import_zendesk_endpoint',
        description: __('Defines a Zendesk endpoint to import users, tickets, states, and articles.'),
      },
      {
        title:       __('Stats Backend'),
        name:        'Stats::TicketWaitingTime',
        description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
      },
      {
        title:       __('Stats Backend'),
        name:        'Stats::TicketEscalation',
        description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
      },
      {
        title:       __('Stats Backend'),
        name:        'Stats::TicketChannelDistribution',
        description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
      },
      {
        title:       __('Stats Backend'),
        name:        'Stats::TicketLoadMeasure',
        description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
      },
      {
        title:       __('Stats Backend'),
        name:        'Stats::TicketInProcess',
        description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
      },
      {
        title:       __('Stats Backend'),
        name:        'Stats::TicketReopen',
        description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
      },
      {
        title:       __('Import Password for HTTP basic authentication'),
        name:        'import_otrs_password',
        description: __('Defines HTTP basic authentication password (only if OTRS is protected via HTTP basic auth).'),
      },
      {
        title:       __('Developer System'),
        name:        'developer_mode',
        description: __('Defines if the application is in developer mode (all users have the same password and password reset will work without email delivery).'),
      },
      {
        title:       __('Group selection for ticket creation'),
        name:        'form_ticket_create_group_id',
        description: __('Defines the group of tickets created via web form.'),
      },
      {
        title:       __('Limit tickets by IP per day'),
        name:        'form_ticket_create_by_ip_per_day',
        description: __('Defines a limit for how many tickets can be created via web form from one IP address per day.'),
      },
      {
        title:       __('Limit tickets by IP per hour'),
        name:        'form_ticket_create_by_ip_per_hour',
        description: __('Defines a limit for how many tickets can be created via web form from one IP address per hour.'),
      },
      {
        title:       __('Limit tickets per day'),
        name:        'form_ticket_create_per_day',
        description: __('Defines a limit for how many tickets can be created via web form per day.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '5400_postmaster_filter_jira_check',
        description: __('Defines postmaster filter to identify Jira mails for correct follow-ups.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '5401_postmaster_filter_jira_check',
        description: __('Defines postmaster filter to identify Jira mails for correct follow-ups.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '0950_postmaster_filter_bounce_delivery_permanent_failed',
        description: __('Defines postmaster filter to identify postmaster bounces; and disables sending notification if delivery fails permanently.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '0955_postmaster_filter_bounce_delivery_temporary_failed',
        description: __('Defines postmaster filter to identify postmaster bounces; and reopens tickets if delivery fails permanently.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '0900_postmaster_filter_bounce_follow_up_check',
        description: __('Defines postmaster filter to identify postmaster bounces; and handles them as follow-up of the original tickets'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '5400_postmaster_filter_service_now_check',
        description: __('Defines postmaster filter to identify ServiceNow mails for correct follow-ups.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '5401_postmaster_filter_service_now_check',
        description: __('Defines postmaster filter to identify ServiceNow mails for correct follow-ups.'),
      },
      {
        title:       __('Defines postmaster filter.'),
        name:        '0005_postmaster_filter_trusted',
        description: __('Defines postmaster filter to remove X-Zammad headers from untrustworthy sources.'),
      },
      {
        title:       __('HTML Email CSS Font'),
        name:        'html_email_css_font',
        description: __('Defines the CSS font information for HTML emails.'),
      },
      {
        title:       __('Geo IP Service'),
        name:        'geo_ip_backend',
        description: __('Defines the backend for geo IP lookups. Also shows location of an IP address if it is traceable.'),
      },
      {
        title:       __('CTI config'),
        name:        'cti_config',
        description: __('Defines the CTI config.'),
      },
      {
        title:       __('Set agent limit'),
        name:        'system_agent_limit',
        description: __('Defines the agent limit.'),
      },
      {
        title:       __('Product Name'),
        name:        'product_name',
        description: __('Defines the name of the application, shown in the web interface, tabs, and title bar of the web browser.'),
      },
      {
        title:       __('Define postmaster filter.'),
        name:        '5500_postmaster_internal_article_check',
        description: __('Defines postmaster filter which sets the articles visibility to internal if it is a rely to an internal article or the last outgoing email is internal.'),
      },
      {
        title:       __('CTI customer last activity'),
        name:        'cti_customer_last_activity',
        description: __('Defines the duration of customer activity (in seconds) on a call until the user profile dialog is shown.'),
      },
      {
        title:       __('Slack config'),
        name:        'slack_config',
        description: __('Defines the Slack config.'),
      },
      {
        title:       __('Auto-close state'),
        name:        'icinga_auto_close_state_id',
        description: __('Defines the state of auto-closed tickets.'),
      },
      {
        title:       __('Auto-close state'),
        name:        'nagios_auto_close_state_id',
        description: __('Defines the state of auto-closed tickets.'),
      },
      {
        title:       __('Auto-close state'),
        name:        'check_mk_auto_close_state_id',
        description: __('Defines the state of auto-closed tickets.'),
      },
      {
        title:       __('Auto-close state'),
        name:        'check_mk_auto_close_state_id',
        description: __('Defines the state of auto-closed tickets.'),
      },
      {
        title:       __('Locale'),
        name:        'locale_default',
        description: __('Defines the default system language.'),
      },
      {
        title:       __('Timezone'),
        name:        'timezone_default',
        description: __('Defines the default system timezone.'),
      },
      {
        title:       __('Defines transaction backend.'),
        name:        '9100_cti_caller_id_detection',
        description: __('Defines the transaction backend which detects caller IDs in objects and stores them for CTI lookups.'),
      },
      {
        title:       __('User Organization Selector - email'),
        name:        'ui_user_organization_selector_with_email',
        description: __('Defines if the email should be displayed in the result of the user/organization widget.'),
      },
      {
        title:       __('GitHub App Credentials'),
        name:        'auth_github_credentials',
        description: __('Enables user authentication via GitHub.'),
      },
      {
        title:       __('Customer selection based on sender and receiver list'),
        name:        'postmaster_sender_is_agent_search_for_customer',
        description: __('If the sender is an agent, set the first user in the recipient list as the customer.'),
      },
      {
        title:       __('Import API key for requesting the Freshdesk API'),
        name:        'import_freshdesk_endpoint_key',
        description: __('Defines Freshdesk endpoint authentication API key.'),
      },
      {
        title:       __('Import API key for requesting the Zendesk API'),
        name:        'import_zendesk_endpoint_key',
        description: __('Defines Zendesk endpoint authentication API key.'),
      },
      {
        title:       __('Knowledge Base active'),
        name:        'kb_active',
        description: __('Defines if Knowledge Base navbar button is enabled.'),
      },
      {
        title:       __('Knowledge Base active publicly'),
        name:        'kb_active_publicly',
        description: __('Defines if Knowledge Base navbar button is enabled for users without Knowledge Base permission.'),
      },
      {
        title:       __('Knowledge Base multilingual support'),
        name:        'kb_multi_lingual_support',
        description: __('Support of multilingual Knowledge Base.'),
      },
      {
        title:       __('Maximum Email Size'),
        name:        'postmaster_max_size',
        description: __('Defines the maximum accepted email size in MB.'),
      },
      {
        title:       __('Maximum failed logins'),
        name:        'password_max_login_failed',
        description: __('Defines after how many failed logins accounts will be deactivated.'),
      },
      {
        title:       __('Sender based on Reply-To header'),
        name:        'postmaster_sender_based_on_reply_to',
        description: __('Set/overwrite sender/from of email based on "Reply-To" header. Useful to set correct customer if email is received from a third-party system on behalf of a customer.'),
      },
      {
        title:       __('Ticket Last Contact Behaviour'),
        name:        'ticket_last_contact_behaviour',
        description: __('Sets the last customer contact based on either the last contact of the customer in general or on the last contact of the customer that has not received a response.'),
      },
      {
        title:       __('CTI Token'),
        name:        'cti_token',
        description: __('Token for CTI.'),
      },
      {
        title:       __('CTI integration'),
        name:        'cti_integration',
        description: __('Defines if generic CTI integration is enabled or not.'),
      },
      {
        title:       __('Placetel Token'),
        name:        'placetel_token',
        description: __('Defines the token for Placetel.'),
      },
    ]

    settings_update.each do |setting|
      fetched_setting = Setting.find_by(name: setting[:name])
      next if !fetched_setting

      if setting[:title]
        # "Updating title of #{setting[:name]} to #{setting[:title]}"
        fetched_setting.title = setting[:title]
      end

      if setting[:description]
        # "Updating description of #{setting[:name]} to #{setting[:description]}"
        fetched_setting.description = setting[:description]
      end

      fetched_setting.save!
    end
  end
end
