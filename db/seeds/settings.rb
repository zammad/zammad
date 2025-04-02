# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Setting.create_if_not_exists(
  title:       __('Application secret'),
  name:        'application_secret',
  area:        'Core',
  description: __('Defines the random application secret.'),
  options:     {},
  state:       SecureRandom.hex(128),
  preferences: {
    permission: ['admin'],
    protected:  true,
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('System Init Done'),
  name:        'system_init_done',
  area:        'Core',
  description: __('Defines if application is in init mode.'),
  options:     {},
  state:       false,
  preferences: { online_service_disable: true },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('App Version'),
  name:        'app_version',
  area:        'Core::WebApp',
  description: __('Only used internally to propagate current web app version to clients.'),
  options:     {},
  state:       '',
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Maintenance Mode'),
  name:        'maintenance_mode',
  area:        'Core::WebApp',
  description: __('Enable or disable the maintenance mode of Zammad. If enabled, all non-administrators get logged out and only administrators can start a new session.'),
  options:     {},
  state:       false,
  preferences: {
    permission: ['admin.maintenance'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Maintenance Login'),
  name:        'maintenance_login',
  area:        'Core::WebApp',
  description: __('Put a message on the login page. To change it, click on the text area below and change it in-line.'),
  options:     {},
  state:       false,
  preferences: {
    permission: ['admin.maintenance'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Maintenance Login'),
  name:        'maintenance_login_message',
  area:        'Core::WebApp',
  description: __('Message for login page.'),
  options:     {},
  state:       __('This is a default maintenance message. Click here to change.'),
  preferences: {
    permission: ['admin.maintenance'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Developer System'),
  name:        'developer_mode',
  area:        'Core::Develop',
  description: __('Defines if the application is in developer mode (all users have the same password and password reset will work without email delivery).'),
  options:     {},
  state:       Rails.env.development?,
  preferences: { online_service_disable: true },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Online Service'),
  name:        'system_online_service',
  area:        'Core',
  description: __('Defines if application is used as online service.'),
  options:     {},
  state:       false,
  preferences: { online_service_disable: true },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Product Name'),
  name:        'product_name',
  area:        'System::Branding',
  description: __('Defines the name of the application, shown in the web interface, tabs, and title bar of the web browser.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'product_name',
        tag:     'input',
      },
    ],
  },
  preferences: {
    render:      true,
    prio:        1,
    placeholder: true,
    permission:  ['admin.branding'],
  },
  state:       __('Zammad Helpdesk'),
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Logo'),
  name:        'product_logo',
  area:        'System::Branding',
  description: __('Defines the logo of the application, shown in the web interface.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'product_logo',
        tag:     'input',
      },
    ],
  },
  preferences: {
    prio:       3,
    controller: 'SettingsAreaLogo',
    permission: ['admin.branding'],
  },
  state:       'logo.svg',
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Organization'),
  name:        'organization',
  area:        'System::Branding',
  description: __('Will be shown in the app and is included in email footers.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'organization',
        tag:     'input',
      },
    ],
  },
  state:       '',
  preferences: {
    prio:        2,
    placeholder: true,
    permission:  ['admin.branding'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Locale'),
  name:        'locale_default',
  area:        'System::Branding',
  description: __('Defines the default system language.'),
  options:     {
    form: [
      {
        name: 'locale_default',
      }
    ],
  },
  state:       'en-us',
  preferences: {
    prio:       8,
    controller: 'SettingsAreaItemDefaultLocale',
    permission: ['admin.system'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Language Detection Service'),
  name:        'language_detection_article',
  area:        'Ticket::LanguageDetection',
  description: __('Defines the backend service for ticket article language detection.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'language_detection_article',
        tag:     'select',
        options: {
          ''    => '-',
          'cld' => 'Compact Language Detector (CLD)', # rubocop:disable Zammad/DetectTranslatableString
        },
      },
    ],
  },
  state:       '',
  preferences: {},
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Timezone'),
  name:        'timezone_default',
  area:        'System::Branding',
  description: __('Defines the default system timezone.'),
  options:     {
    form: [
      {
        name: 'timezone_default',
      }
    ],
  },
  state:       'UTC',
  preferences: {
    prio:        9,
    controller:  'SettingsAreaItemDefaultTimezone',
    permission:  ['admin.system'],
    validations: ['Setting::Validation::TimeZone'],
  },
  frontend:    true
)
Setting.create_or_update(
  title:       __('Pretty Date'),
  name:        'pretty_date_format',
  area:        'System::Branding',
  description: __('Defines pretty date format.'),
  options:     {
    form: [
      {
        display:   '',
        null:      false,
        name:      'pretty_date_format',
        tag:       'select',
        options:   {
          relative:  __('relative - e. g. "2 hours ago" or "2 days and 15 minutes ago"'),
          absolute:  __('absolute - e. g. "Monday 09:30" or "Tuesday 23. Feb 14:20"'),
          timestamp: __('timestamp - e. g. "2018-08-30 14:30"'),
        },
        translate: true,
      },
    ],
  },
  preferences: {
    render:     true,
    prio:       10,
    permission: ['admin.branding'],
  },
  state:       'relative',
  frontend:    true
)
options = {}
(10..99).each do |item|
  options[item] = item
end
system_id = rand(10..99) # rubocop:disable Zammad/ForbidRand
Setting.create_if_not_exists(
  title:       __('SystemID'),
  name:        'system_id',
  area:        'System::Base',
  description: __('Defines the system identifier. Every ticket number contains this ID. This ensures that only tickets which belong to your system will be processed as follow-ups (useful when communicating between two instances of Zammad).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'system_id',
        tag:     'select',
        options: options,
      },
    ],
  },
  state:       system_id,
  preferences: {
    online_service_disable: true,
    placeholder:            true,
    authentication:         true,
    permission:             ['admin.system'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Fully Qualified Domain Name'),
  name:        'fqdn',
  area:        'System::Base',
  description: __('Defines the fully qualified domain name of the system. This setting is used as a variable, #{setting.fqdn} which is found in all forms of messaging used by the application, to build links to the tickets within your system.'), # rubocop:disable Lint/InterpolationCheck
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'fqdn',
        tag:     'input',
      },
    ],
  },
  state:       'zammad.example.com',
  preferences: {
    online_service_disable: true,
    placeholder:            true,
    permission:             ['admin.system'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Websocket backend'),
  name:        'websocket_backend',
  area:        'System::WebSocket',
  description: __('Defines how to reach websocket server. "websocket" is default on production, "websocketPort" is for CI'),
  state:       Rails.env.production? ? 'websocket' : 'websocketPort',
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Websocket port'),
  name:        'websocket_port',
  area:        'System::WebSocket',
  description: __('Defines the port of the websocket server.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'websocket_port',
        tag:     'input',
      },
    ],
  },
  state:       '6042',
  preferences: { online_service_disable: true },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('HTTP type'),
  name:        'http_type',
  area:        'System::Base',
  description: __('Defines the HTTP protocol of your instance.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'http_type',
        tag:     'select',
        options: {
          'https' => 'https',
          'http'  => 'http',
        },
      },
    ],
  },
  state:       'http',
  preferences: {
    online_service_disable: true,
    placeholder:            true,
    permission:             ['admin.system'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Storage Method'),
  name:        'storage_provider',
  area:        'System::Storage',
  description: __('"Database" stores all attachments in the database (not recommended for storing large amounts of data). "Filesystem" stores the data in the filesystem. "Simple Storage (S3)" stores the data in a remote S3 compatible object filesystem. You can switch between the modules even on a system that is already in production without any loss of data.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'storage_provider',
        tag:       'select',
        options:   {
          'DB'   => __('Database'),
          'File' => __('Filesystem'),
          'S3'   => __('Simple Storage (S3)'),
        },
        translate: true,
      },
    ],
  },
  state:       'DB',
  preferences: {
    controller:             'SettingsAreaStorageProvider',
    online_service_disable: true,
    permission:             ['admin.system'],
    validations:            ['Setting::Validation::StorageProvider'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Image Service'),
  name:        'image_backend',
  area:        'System::Services',
  description: __('Defines the backend for user and organization image lookups.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'image_backend',
        tag:     'select',
        options: {
          ''                       => '-',
          'Service::Image::Zammad' => 'Zammad Image Service', # rubocop:disable Zammad/DetectTranslatableString
        },
      },
    ],
  },
  state:       'Service::Image::Zammad',
  preferences: {
    prio:       1,
    permission: ['admin.system'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Geo IP Service'),
  name:        'geo_ip_backend',
  area:        'System::Services',
  description: __('Defines the backend for geo IP lookups. Also shows location of an IP address if it is traceable.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'geo_ip_backend',
        tag:     'select',
        options: {
          ''                       => '-',
          'Service::GeoIp::Zammad' => 'Zammad GeoIP Service', # rubocop:disable Zammad/DetectTranslatableString
        },
      },
    ],
  },
  state:       'Service::GeoIp::Zammad',
  preferences: {
    prio:       2,
    permission: ['admin.system'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Geo Location Service'),
  name:        'geo_location_backend',
  area:        'System::Services',
  description: __('Defines the backend for geo location lookups to store geo locations for addresses.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'geo_location_backend',
        tag:     'select',
        options: {
          ''                          => '-',
          'Service::GeoLocation::Osm' => 'OpenStreetMap (ODbL 1.0, http://osm.org/copyright)', # rubocop:disable Zammad/DetectTranslatableString
        },
      },
    ],
  },
  state:       'Service::GeoLocation::Osm',
  preferences: {
    prio:       3,
    permission: ['admin.system'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Geo Calendar Service'),
  name:        'geo_calendar_backend',
  area:        'System::Services',
  description: __('Defines the backend for geo calendar lookups. Used for initial calendar succession.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'geo_calendar_backend',
        tag:     'select',
        options: {
          ''                             => '-',
          'Service::GeoCalendar::Zammad' => 'Zammad GeoCalendar Service', # rubocop:disable Zammad/DetectTranslatableString
        },
      },
    ],
  },
  state:       'Service::GeoCalendar::Zammad',
  preferences: {
    prio:       2,
    permission: ['admin.system'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Proxy Settings'),
  name:        'proxy',
  area:        'System::Network',
  description: __('Address of the proxy server for http and https resources.'),
  options:     {
    form: [
      {
        display:     '',
        null:        false,
        name:        'proxy',
        tag:         'input',
        placeholder: 'proxy.example.com:3128',
      },
    ],
  },
  state:       '',
  preferences: {
    online_service_disable: true,
    controller:             'SettingsAreaProxy',
    prio:                   1,
    permission:             ['admin.system'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Proxy User'),
  name:        'proxy_username',
  area:        'System::Network',
  description: __('Username for proxy connection.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'proxy_username',
        tag:     'input',
      },
    ],
  },
  state:       '',
  preferences: {
    disabled:               true,
    online_service_disable: true,
    prio:                   2,
    permission:             ['admin.system'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Proxy Password'),
  name:        'proxy_password',
  area:        'System::Network',
  description: __('Password for proxy connection.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'proxy_password',
        tag:     'input',
      },
    ],
  },
  state:       '',
  preferences: {
    disabled:               true,
    online_service_disable: true,
    prio:                   3,
    permission:             ['admin.system'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('No Proxy'),
  name:        'proxy_no',
  area:        'System::Network',
  description: __('No proxy for the following hosts.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'proxy_no',
        tag:     'input',
      },
    ],
  },
  state:       'localhost,127.0.0.0,::1',
  preferences: {
    disabled:               true,
    online_service_disable: true,
    prio:                   4,
    permission:             ['admin.system'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Core Workflow Ajax Mode'),
  name:        'core_workflow_ajax_mode',
  area:        'System::UI',
  description: __('Defines if the core workflow communication should run over ajax instead of websockets.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'core_workflow_ajax_mode',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       3,
    permission: ['admin.system'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('User Organization Selector - email'),
  name:        'ui_user_organization_selector_with_email',
  area:        'UI::UserOrganizatiomSelector',
  description: __('Defines if the email should be displayed in the result of the user/organization widget.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_user_organization_selector_with_email',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       100,
    permission: ['admin.ui'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Note - default visibility'),
  name:        'ui_ticket_zoom_article_note_new_internal',
  area:        'UI::TicketZoom',
  description: __('Defines the default visibility for new notes.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_zoom_article_note_new_internal',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'internal',
          false => 'public',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       100,
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Article - visibility confirmation dialog'),
  name:        'ui_ticket_zoom_article_visibility_confirmation_dialog',
  area:        'UI::TicketZoom',
  description: __('Defines if the agent has to accept a confirmation dialog when changing the article visibility to "public".'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ui_ticket_zoom_article_visibility_confirmation_dialog',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       100,
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Email - subject field'),
  name:        'ui_ticket_zoom_article_email_subject',
  area:        'UI::TicketZoom',
  description: __('Use subject field for emails. If disabled, the ticket title will be used as subject.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_zoom_article_email_subject',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       200,
    permission: ['admin.ui'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Email - full quote'),
  name:        'ui_ticket_zoom_article_email_full_quote',
  area:        'UI::TicketZoom',
  description: __('Enable if you want to quote the full email in your answer. The quoted email will be put at the end of your answer. If you just want to quote a certain phrase, just mark the text and press reply (this feature is always available).'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_zoom_article_email_full_quote',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       220,
    permission: ['admin.ui'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Email - quote header'),
  name:        'ui_ticket_zoom_article_email_full_quote_header',
  area:        'UI::TicketZoom',
  description: __('Enable if you want a timestamped reply header to be automatically inserted in front of quoted messages.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_zoom_article_email_full_quote_header',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       240,
    permission: ['admin.ui'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Twitter - tweet initials'),
  name:        'ui_ticket_zoom_article_twitter_initials',
  area:        'UI::TicketZoom',
  description: __('Add sender initials to end of a tweet.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_zoom_article_twitter_initials',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       300,
    permission: ['admin.ui'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Sidebar Attachments'),
  name:        'ui_ticket_zoom_attachments_preview',
  area:        'UI::TicketZoom::Preview',
  description: __('Enables preview of attachments.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_zoom_attachments_preview',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       400,
    permission: ['admin.ui'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Sidebar Attachments'),
  name:        'ui_ticket_zoom_sidebar_article_attachments',
  area:        'UI::TicketZoom::Preview',
  description: __('Enables a sidebar to show an overview of all attachments.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_zoom_sidebar_article_attachments',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       500,
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Additional notes for ticket create types.'),
  name:        'ui_ticket_create_notes',
  area:        'UI::TicketCreate',
  description: __('Show additional notes for ticket creation depending on the selected type.'),
  options:     {},
  state:       {
    # 'email-out' => __('Attention: When creating a ticket an email is sent.'),
  },
  preferences: {
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Default type for a new ticket'),
  name:        'ui_ticket_create_default_type',
  area:        'UI::TicketCreate',
  description: __('Select default ticket type'),
  options:     {
    form: [
      {
        display:  '',
        null:     false,
        multiple: false,
        name:     'ui_ticket_create_default_type',
        tag:      'select',
        options:  {
          'phone-in'  => '1. Phone inbound',
          'phone-out' => '2. Phone outbound',
          'email-out' => '3. Email outbound',
        },
      },
    ],
  },
  state:       'phone-in',
  preferences: {
    permission: ['admin.ui']
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Available types for a new ticket'),
  name:        'ui_ticket_create_available_types',
  area:        'UI::TicketCreate',
  description: __('Set available ticket types'),
  options:     {
    form: [
      {
        display:  '',
        null:     false,
        multiple: true,
        name:     'ui_ticket_create_available_types',
        tag:      'select',
        options:  {
          'phone-in'  => '1. Phone inbound',
          'phone-out' => '2. Phone outbound',
          'email-out' => '3. Email outbound',
        },
      },
    ],
  },
  state:       %w[phone-in phone-out email-out],
  preferences: {
    permission: ['admin.ui']
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Open ticket indicator'),
  name:        'ui_sidebar_open_ticket_indicator_colored',
  area:        'UI::Sidebar',
  description: __('Color representation of the open ticket indicator in the sidebar.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_sidebar_open_ticket_indicator_colored',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Open ticket indicator'),
  name:        'ui_table_group_by_show_count',
  area:        'UI::Base',
  description: __('Total display of the number of objects in a grouping.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_table_group_by_show_count',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Ticket Priority Icons'),
  name:        'ui_ticket_priority_icons',
  area:        'UI::Ticket::Priority',
  description: __('Enables display of ticket priority icons in UI.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ui_ticket_priority_icons',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       500,
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Maximum number of ticket shown in overviews'),
  name:        'ui_ticket_overview_ticket_limit',
  area:        'UI::TicketOverview::TicketLimit',
  description: __('Define the maximum number of ticket shown in overviews.'),
  options:     {},
  state:       2000,
  preferences: {
    permission: ['admin.overview'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Maximum number of open tabs.'),
  name:        'ui_task_mananger_max_task_count',
  area:        'UI::TaskManager::Task::MaxCount',
  description: __('Defines the maximum number of allowed open tabs before auto cleanup removes surplus tabs when creating new tabs.'),
  options:     {},
  state:       30,
  preferences: {
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Password Login'),
  name:        'user_show_password_login',
  area:        'Security::Base',
  description: __('Show password login for users on login page. Disabling only takes effect if third-party authentication is enabled.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'user_show_password_login',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       5,
    permission: ['admin.security'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('New User Accounts'),
  name:        'user_create_account',
  area:        'Security::Base',
  description: __('Enables users to create their own account via web interface. This setting is only effective if the password login is enabled.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'user_create_account',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       10,
    permission: ['admin.security'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Lost Password'),
  name:        'user_lost_password',
  area:        'Security::Base',
  description: __('Activates lost password feature for users. This setting is only effective if the password login is enabled.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'user_lost_password',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       20,
    permission: ['admin.security'],
  },
  frontend:    true
)

options = [ { value: '0', name: 'disabled' }, { value: 1.hour.seconds.to_s, name: __('1 hour') }, { value: 2.hours.seconds.to_s, name: __('2 hours') }, { value: 1.day.seconds.to_s, name: __('1 day') }, { value: 7.days.seconds.to_s, name: __('1 week') }, { value: 14.days.seconds.to_s, name: __('2 weeks') }, { value: 21.days.seconds.to_s, name: __('3 weeks') }, { value: 28.days.seconds.to_s, name: __('4 weeks') } ]
Setting.create_if_not_exists(
  title:       __('Session Timeout'),
  name:        'session_timeout',
  area:        'Security::Base',
  description: __('Defines the session timeout for inactivity of users. Based on the assigned permissions the highest timeout value will be used, otherwise the default.'),
  options:     {
    form: [
      {
        display:   __('Default'),
        null:      false,
        name:      'default',
        tag:       'select',
        options:   options,
        translate: true,
      },
      {
        display:   __('admin'),
        null:      false,
        name:      'admin',
        tag:       'select',
        options:   options,
        translate: true,
      },
      {
        display:   __('ticket.agent'),
        null:      false,
        name:      'ticket.agent',
        tag:       'select',
        options:   options,
        translate: true,
      },
      {
        display:   __('ticket.customer'),
        null:      false,
        name:      'ticket.customer',
        tag:       'select',
        options:   options,
        translate: true,
      },
    ],
  },
  preferences: {
    prio: 30,
  },
  state:       {
    'default'         => 4.weeks.seconds.to_s,
    'admin'           => 4.weeks.seconds.to_s,
    'ticket.agent'    => 4.weeks.seconds.to_s,
    'ticket.customer' => 4.weeks.seconds.to_s,
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('User email for multiple users'),
  name:        'user_email_multiple_use',
  area:        'Model::User',
  description: __('Allow using one email address for multiple users.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'user_email_multiple_use',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    permission: ['admin'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_internal',
  area:        'Security::Authentication',
  description: __('Enables user authentication via %s.'),
  preferences: {
    title_i18n:       [__('internal database')],
    description_i18n: [__('internal database')],
    permission:       ['admin.security'],
  },
  state:       {
    priority: 1,
    adapter:  'Auth::Backend::Internal',
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_developer',
  area:        'Security::Authentication',
  description: __('Enables user authentication via %s.'),
  preferences: {
    title_i18n:       [__('developer password')],
    description_i18n: [__('developer password')],
    permission:       ['admin.security'],
  },
  state:       {
    priority: 2,
    adapter:  'Auth::Backend::Developer',
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_ldap',
  area:        'Security::Authentication',
  description: __('Enables user authentication via %s.'),
  preferences: {
    title_i18n:       [__('LDAP')],
    description_i18n: [__('LDAP')],
    permission:       ['admin.security'],
  },
  state:       {
    priority:      3,
    adapter:       'Auth::Backend::Ldap',
    host:          'localhost',
    port:          389,
    bind_dn:       'cn=Manager,dc=example,dc=org',
    bind_pw:       'example',
    uid:           'mail',
    base:          'dc=example,dc=org',
    always_filter: '',
    always_roles:  %w[Admin Agent],
    always_groups: ['Users'],
    sync_params:   {
      firstname: 'sn',
      lastname:  'givenName',
      email:     'mail',
      login:     'mail',
    },
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Automatic account link on initial logon'),
  name:        'auth_third_party_auto_link_at_inital_login',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables the automatic linking of an existing account on initial login via a third party application. If this is disabled, an existing user must first log into Zammad and then link his "Third Party" account to his Zammad account via Profile -> Linked Accounts.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_third_party_auto_link_at_inital_login',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    permission: ['admin.security'],
    prio:       10,
  },
  state:       false,
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Automatic account linking notification'),
  name:        'auth_third_party_linking_notification',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables sending of an email notification to a user when they link their account with a third-party application.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_third_party_linking_notification',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    permission: ['admin.security'],
    prio:       20,
  },
  state:       false,
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('No user creation on logon'),
  name:        'auth_third_party_no_create_user',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Disables user creation on logon with a third-party application.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_third_party_no_create_user',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    permission: ['admin.security'],
    prio:       20,
  },
  state:       false,
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_twitter',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_twitter',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_twitter_credentials'],
    title_i18n:       [__('Twitter')],
    description_i18n: [__('Twitter'), __('Twitter Developer Site'), 'https://dev.twitter.com/apps'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Twitter App Credentials'),
  name:        'auth_twitter_credentials',
  area:        'Security::ThirdPartyAuthentication::Twitter',
  description: __('App credentials for Twitter.'),
  options:     {
    form: [
      {
        display: __('Twitter Key'),
        null:    true,
        name:    'key',
        tag:     'input',
      },
      {
        display: __('Twitter Secret'),
        null:    true,
        name:    'secret',
        tag:     'input',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_twitter',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_facebook',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_facebook',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_facebook_credentials'],
    title_i18n:       [__('Facebook')],
    description_i18n: [__('Facebook'), __('Facebook Developer Site'), 'https://developers.facebook.com/apps/'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Facebook App Credentials'),
  name:        'auth_facebook_credentials',
  area:        'Security::ThirdPartyAuthentication::Facebook',
  description: __('App credentials for Facebook.'),
  options:     {
    form: [
      {
        display: __('App ID'),
        null:    true,
        name:    'app_id',
        tag:     'input',
      },
      {
        display: __('App Secret'),
        null:    true,
        name:    'app_secret',
        tag:     'input',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_facebook',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_google_oauth2',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_google_oauth2',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_google_oauth2_credentials'],
    title_i18n:       [__('Google')],
    description_i18n: [__('Google'), __('Google API Console Site'), 'https://console.cloud.google.com/apis/credentials'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Google App Credentials'),
  name:        'auth_google_oauth2_credentials',
  area:        'Security::ThirdPartyAuthentication::Google',
  description: __('Enables user authentication via Google.'),
  options:     {
    form: [
      {
        display: __('Client ID'),
        null:    true,
        name:    'client_id',
        tag:     'input',
      },
      {
        display: __('Client Secret'),
        null:    true,
        name:    'client_secret',
        tag:     'input',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_google_oauth2',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_linkedin',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_linkedin',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_linkedin_credentials'],
    title_i18n:       [__('LinkedIn')],
    description_i18n: [__('LinkedIn'), __('LinkedIn Developer Site'), 'https://www.linkedin.com/developer/apps'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('LinkedIn App Credentials'),
  name:        'auth_linkedin_credentials',
  area:        'Security::ThirdPartyAuthentication::Linkedin',
  description: __('Enables user authentication via LinkedIn.'),
  options:     {
    form: [
      {
        display: __('App ID'),
        null:    true,
        name:    'app_id',
        tag:     'input',
      },
      {
        display: __('App Secret'),
        null:    true,
        name:    'app_secret',
        tag:     'input',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_linkedin',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_github',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_github',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_github_credentials'],
    title_i18n:       [__('GitHub')],
    description_i18n: [__('GitHub'), __('GitHub OAuth Applications'), 'https://github.com/settings/applications'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('GitHub App Credentials'),
  name:        'auth_github_credentials',
  area:        'Security::ThirdPartyAuthentication::Github',
  description: __('Enables user authentication via GitHub.'),
  options:     {
    form: [
      {
        display: __('App ID'),
        null:    true,
        name:    'app_id',
        tag:     'input',
      },
      {
        display: __('App Secret'),
        null:    true,
        name:    'app_secret',
        tag:     'input',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_github',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_gitlab',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_gitlab',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_gitlab_credentials'],
    title_i18n:       [__('GitLab')],
    description_i18n: [__('GitLab'), __('GitLab Applications'), 'https://your-gitlab-host/admin/applications'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('GitLab App Credentials'),
  name:        'auth_gitlab_credentials',
  area:        'Security::ThirdPartyAuthentication::GitLab',
  description: __('Enables user authentication via GitLab.'),
  options:     {
    form: [
      {
        display: __('App ID'),
        null:    true,
        name:    'app_id',
        tag:     'input',
      },
      {
        display: __('App Secret'),
        null:    true,
        name:    'app_secret',
        tag:     'input',
      },
      {
        display:     __('Site'),
        null:        true,
        name:        'site',
        tag:         'input',
        placeholder: 'https://gitlab.YOURDOMAIN.com/',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_gitlab',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_microsoft_office365',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_microsoft_office365',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_microsoft_office365_credentials'],
    title_i18n:       [__('Microsoft')],
    description_i18n: [__('Microsoft'), __('Microsoft Application Registration Portal'), 'https://portal.azure.com'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Microsoft 365 App Credentials'),
  name:        'auth_microsoft_office365_credentials',
  area:        'Security::ThirdPartyAuthentication::Office365',
  description: __('Enables user authentication via Microsoft 365.'),
  options:     {
    form: [
      {
        display: __('App ID'),
        null:    true,
        name:    'app_id',
        tag:     'input',
      },
      {
        display: __('App Secret'),
        null:    true,
        name:    'app_secret',
        tag:     'input',
      },
      {
        display:     __('App Tenant ID'),
        null:        true,
        name:        'app_tenant',
        tag:         'input',
        placeholder: 'common',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_microsoft_office365',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_weibo',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s. Register your app first at [%s](%s).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_weibo',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_weibo_credentials'],
    title_i18n:       [__('Weibo')],
    description_i18n: [__('Sina Weibo'), __('Sina Weibo Open Portal'), 'http://open.weibo.com'],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Weibo App Credentials'),
  name:        'auth_weibo_credentials',
  area:        'Security::ThirdPartyAuthentication::Weibo',
  description: __('Enables user authentication via Weibo.'),
  options:     {
    form: [
      {
        display: __('App ID'),
        null:    true,
        name:    'client_id',
        tag:     'input',
      },
      {
        display: __('App Secret'),
        null:    true,
        name:    'client_secret',
        tag:     'input',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_weibo',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_saml',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_saml',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_saml_credentials'],
    title_i18n:       [__('SAML')],
    description_i18n: [__('SAML')],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('SAML App Credentials'),
  name:        'auth_saml_credentials',
  area:        'Security::ThirdPartyAuthentication::SAML',
  description: __('Enables user authentication via SAML.'),
  options:     {
    form: [
      {
        display:     __('Display name'),
        null:        true,
        name:        'display_name',
        tag:         'input',
        placeholder: __('SAML'),
      },
      {
        display:     __('IDP SSO target URL'),
        null:        true,
        name:        'idp_sso_target_url',
        tag:         'input',
        placeholder: 'https://capriza.github.io/samling/samling.html',
        required:    true,
      },
      {
        display:     __('IDP Single Logout target URL'),
        null:        true,
        name:        'idp_slo_service_url',
        tag:         'input',
        placeholder: 'https://capriza.github.io/samling/slo.html',
        required:    true,
      },
      {
        display:     __('IDP certificate'),
        null:        true,
        name:        'idp_cert',
        tag:         'textarea',
        placeholder: '-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----',
        required:    true,
      },
      {
        display:     __('IDP certificate fingerprint'),
        null:        true,
        name:        'idp_cert_fingerprint',
        tag:         'input',
        placeholder: 'E7:91:B2:E1:...',
        help:        __('Please note that this attribute is deprecated within one of the next versions of Zammad. Use the IDP certificate instead.'),
      },
      {
        display:     __('Name Identifier Format'),
        null:        true,
        name:        'name_identifier_format',
        tag:         'input',
        placeholder: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress',
        required:    true,
      },
      {
        display:     __('UID Attribute Name'),
        null:        true,
        name:        'uid_attribute',
        tag:         'input',
        placeholder: '',
        help:        __('Attribute that uniquely identifies the user. If unset, the name identifier returned by the IDP is used.')
      },
      {
        display: 'SSL verification',
        name:    'ssl_verify',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
        default: true,
        help:    __('Verification of the TLS connection to the IDP SSO target URL. Only relevant during setting up SAML authentication.'),
      },
      {
        display: __('Signing & Encrypting'),
        null:    true,
        name:    'security',
        tag:     'select',
        options: {
          'off'     => __('None'),
          'on'      => __('Signing & Encrypting'),
          'sign'    => __('Only Signing'),
          'encrypt' => __('Only Encrypting'),
        },
      },
      {
        display:     __('Certificate (PEM)'),
        null:        true,
        name:        'certificate',
        tag:         'textarea',
        placeholder: '-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----',
      },
      {
        display:     __('Private key (PEM)'),
        null:        true,
        name:        'private_key',
        tag:         'textarea',
        placeholder: '-----BEGIN RSA PRIVATE KEY-----\n...-----END RSA PRIVATE KEY-----', # gitleaks:allow
      },
      {
        display:     __('Private key secret'),
        null:        true,
        name:        'private_key_secret',
        tag:         'input',
        type:        'password',
        single:      true,
        placeholder: '',
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_saml',
      },
    ],
  },
  state:       {},
  preferences: {
    permission:  ['admin.security'],
    validations: [
      'Setting::Validation::Saml::RequiredAttributes',
      'Setting::Validation::Saml::TLS',
      'Setting::Validation::Saml::Security',
    ],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_openid_connect',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables user authentication via %s.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_openid_connect',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              ['auth_openid_connect_credentials'],
    title_i18n:       [__('OpenID Connect')],
    description_i18n: [__('OpenID Connect')],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('OpenID Connect Options'),
  name:        'auth_openid_connect_credentials',
  area:        'Security::ThirdPartyAuthentication::OpenIDConnect',
  description: __('Enables user authentication via OpenID Connect.'),
  options:     {
    form: [
      {
        display:     __('Display name'),
        null:        true,
        name:        'display_name',
        tag:         'input',
        placeholder: __('OpenID Connect'),
      },
      {
        display:     __('Identifier'),
        null:        true,
        name:        'identifier',
        tag:         'input',
        required:    true,
        placeholder: '',
      },
      {
        display:     __('Issuer'),
        null:        true,
        name:        'issuer',
        tag:         'input',
        placeholder: __('https://example.com'),
        required:    true,
      },
      {
        display:     __('UID Field'),
        null:        true,
        name:        'uid_field',
        tag:         'input',
        placeholder: 'sub',
        help:        __('Field that uniquely identifies the user. If unset, "sub" is used.'),
      },
      {
        display:     __('Scopes'),
        null:        true,
        name:        'scope',
        tag:         'input',
        placeholder: 'openid email profile',
        help:        __('Scopes that are included, separated by a single space character. If unset, "openid email profile" is used.'),
      },
      {
        display:   __('PKCE'),
        null:      true,
        default:   true,
        name:      'pkce',
        tag:       'select',
        options:   {
          true  => 'yes',
          false => 'no',
        },
        translate: true,
        help:      __('Proof Key for Code Exchange is currently only supporting SHA256 as code challenge method.'),
      },
      {
        display:  __('Your callback URL'),
        null:     true,
        name:     'callback_url',
        tag:      'auth_provider',
        provider: 'auth_openid_connect',
      },
    ],
  },
  state:       {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Minimum length'),
  name:        'password_min_size',
  area:        'Security::Password',
  description: __('Password needs to have at least a minimal number of characters.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'password_min_size',
        tag:     'select',
        options: {
          4  => ' 4',
          5  => ' 5',
          6  => ' 6',
          7  => ' 7',
          8  => ' 8',
          9  => ' 9',
          10 => '10',
          11 => '11',
          12 => '12',
          13 => '13',
          14 => '14',
          15 => '15',
          16 => '16',
          17 => '17',
          18 => '18',
          19 => '19',
          20 => '20',
        },
      },
    ],
  },
  state:       10,
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('2 lower case and 2 upper case characters'),
  name:        'password_min_2_lower_2_upper_characters',
  area:        'Security::Password',
  description: __('Password needs to contain 2 lower case and 2 upper case characters.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'password_min_2_lower_2_upper_characters',
        tag:       'select',
        options:   {
          1 => 'yes',
          0 => 'no',
        },
        translate: true,
      },
    ],
  },
  state:       1,
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Digit required'),
  name:        'password_need_digit',
  area:        'Security::Password',
  description: __('Password needs to contain at least one digit.'),
  options:     {
    form: [
      {
        display:   __('Needed'),
        null:      true,
        name:      'password_need_digit',
        tag:       'select',
        options:   {
          1 => 'yes',
          0 => 'no',
        },
        translate: true,
      },
    ],
  },
  state:       1,
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Special character required'),
  name:        'password_need_special_character',
  area:        'Security::Password',
  description: __('Password needs to contain at least one special character.'),
  options:     {
    form: [
      {
        display:   __('Needed'),
        null:      true,
        name:      'password_need_special_character',
        tag:       'select',
        options:   {
          1 => 'yes',
          0 => 'no',
        },
        translate: true,
      },
    ],
  },
  state:       0,
  preferences: {
    permission: ['admin.security'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Maximum failed logins'),
  name:        'password_max_login_failed',
  area:        'Security::Password',
  description: __('Defines after how many failed logins accounts will be deactivated.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'password_max_login_failed',
        tag:     'select',
        options: {
          4  => ' 4',
          5  => ' 5',
          6  => ' 6',
          7  => ' 7',
          8  => ' 8',
          9  => ' 9',
          10 => '10',
          11 => '11',
          13 => '13',
          14 => '14',
          15 => '15',
          16 => '16',
          17 => '17',
          18 => '18',
          19 => '19',
          20 => '20',
        },
      },
    ],
  },
  state:       5,
  preferences: {
    authentication: true,
    permission:     ['admin.security'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Ticket Hook'),
  name:        'ticket_hook',
  area:        'Ticket::Base',
  description: __('The identifier for a ticket, e.g. Ticket#, Call#, MyTicket#. The default is Ticket#.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'ticket_hook',
        tag:     'input',
      },
    ],
  },
  preferences: {
    prio:           1000,
    render:         true,
    placeholder:    true,
    authentication: true,
    permission:     ['admin.ticket'],
  },
  state:       'Ticket#',
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Ticket Hook Divider'),
  name:        'ticket_hook_divider',
  area:        'Ticket::Base::Shadow',
  description: __('The divider between TicketHook and ticket number. E. g. \': \'.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_hook_divider',
        tag:     'input',
      },
    ],
  },
  state:       '',
  preferences: {
    permission: ['admin.ticket'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Hook Position'),
  name:        'ticket_hook_position',
  area:        'Ticket::Base',
  description: __("The format of the subject.
* **Right** means **Some Subject [Ticket#12345]**
* **Left** means **[Ticket#12345] Some Subject**
* **None** means **Some Subject** (without ticket number), in which case it recognizes follow-ups based on email headers."),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ticket_hook_position',
        tag:       'select',
        translate: true,
        options:   {
          'left'  => __('left'),
          'right' => __('right'),
          'none'  => __('none'),
        },
      },
    ],
  },
  state:       'right',
  preferences: {
    prio:       2000,
    controller: 'SettingsAreaTicketHookPosition',
    permission: ['admin.ticket'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Last Contact Behaviour'),
  name:        'ticket_last_contact_behaviour',
  area:        'Ticket::Base',
  description: __('Defines how the last customer contact time of tickets should be calculated.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ticket_last_contact_behaviour',
        tag:       'select',
        translate: true,
        options:   {
          'based_on_customer_reaction'     => __('Use the time of the very last customer article.'),
          'check_if_agent_already_replied' => __('Use the start time of the last customer thread (which may consist of multiple articles).'),
        },
      },
    ],
  },
  state:       'check_if_agent_already_replied',
  preferences: {
    prio:       3000,
    permission: ['admin.ticket'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Conditions Expert Mode'),
  name:        'ticket_allow_expert_conditions',
  area:        'Ticket::Core',
  description: __('Defines if the ticket conditions editor supports complex logical expressions.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_allow_expert_conditions',
        tag:     'boolean',
        options: {
          true  => __('yes'),
          false => __('no'),
        },
      },
    ],
  },
  state:       true,
  preferences: {
    online_service_disable: true,
    permission:             ['admin.ticket'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Ticket Conditions Regular Expression Operators'),
  name:        'ticket_conditions_allow_regular_expression_operators',
  area:        'Ticket::Core',
  description: __('Defines if the ticket conditions editor supports regular expression operators for triggers and ticket auto assignment.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_conditions_allow_regular_expression_operators',
        tag:     'boolean',
        options: {
          true  => __('yes'),
          false => __('no'),
        },
      },
    ],
  },
  state:       true,
  preferences: {
    online_service_disable: true,
    permission:             ['admin.ticket'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Ticket Number Format'),
  name:        'ticket_number',
  area:        'Ticket::Number',
  description: __("Selects the ticket number generator module.
* **Increment** increments the ticket number, the SystemID and the counter are used with SystemID.Counter format (e.g. 1010138, 1010139).
* With **Date** the ticket numbers will be generated by the current date, the SystemID and the counter. The format looks like Year.Month.Day.SystemID.counter (e.g. 201206231010138, 201206231010139)."),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ticket_number',
        tag:       'select',
        translate: true,
        options:   {
          'Ticket::Number::Increment' => __('Increment (SystemID.Counter)'),
          'Ticket::Number::Date'      => __('Date (Year.Month.Day.SystemID.Counter)'),
        },
      },
    ],
  },
  state:       'Ticket::Number::Increment',
  preferences: {
    settings_included: %w[ticket_number_increment ticket_number_date],
    controller:        'SettingsAreaTicketNumber',
    permission:        ['admin.ticket'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Number Increment'),
  name:        'ticket_number_increment',
  area:        'Ticket::Number',
  description: '-',
  options:     {
    form: [
      {
        display: __('Checksum'),
        null:    true,
        name:    'checksum',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
      {
        display: __('Min. size of number'),
        null:    true,
        name:    'min_size',
        tag:     'select',
        options: {
          1  => ' 1',
          2  => ' 2',
          3  => ' 3',
          4  => ' 4',
          5  => ' 5',
          6  => ' 6',
          7  => ' 7',
          8  => ' 8',
          9  => ' 9',
          10 => '10',
          11 => '11',
          12 => '12',
          13 => '13',
          14 => '14',
          15 => '15',
          16 => '16',
          17 => '17',
          18 => '18',
          19 => '19',
          20 => '20',
        },
      },
    ],
  },
  state:       {
    checksum: false,
    min_size: 5,
  },
  preferences: {
    permission: ['admin.ticket'],
    hidden:     true,
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Number Increment Date'),
  name:        'ticket_number_date',
  area:        'Ticket::Number',
  description: '-',
  options:     {
    form: [
      {
        display: __('Checksum'),
        null:    true,
        name:    'checksum',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       {
    checksum: false
  },
  preferences: {
    permission: ['admin.ticket'],
    hidden:     true,
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Auto Assignment'),
  name:        'ticket_auto_assignment',
  area:        'Web::Base',
  description: __('Enable ticket auto assignment.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_auto_assignment',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_auto_assignment'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Auto Assignment Selector'),
  name:        'ticket_auto_assignment_selector',
  area:        'Web::Base',
  description: __('Enable auto assignment for following matching tickets.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_auto_assignment'],
  },
  state:       { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category_ids(:work_on) } } },
  frontend:    true
)
Setting.create_or_update(
  title:       __('Auto Assignment Ignored Users'),
  name:        'ticket_auto_assignment_user_ids_ignore',
  area:        'Web::Base',
  description: __('Define an exception of "automatic assignment" for certain users (e.g. executives).'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_auto_assignment'],
  },
  state:       [],
  frontend:    true
)

Setting.create_or_update(
  title:       __('Default Ticket Agent Notifications'),
  name:        'ticket_agent_default_notifications',
  area:        'Ticket::Core',
  description: __('Define the default agent notifications for new users.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket'],
  },
  state:       {
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
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Detect Duplicate Ticket Creation'),
  name:        'ticket_duplicate_detection',
  area:        'Web::TicketDuplicateDetection',
  description: __('Enables a warning to users during ticket creation if there is an existing ticket with the same attributes.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_duplicate_detection',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection'],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Attributes to compare'),
  name:        'ticket_duplicate_detection_attributes',
  area:        'Web::TicketDuplicateDetection',
  description: __('Defines which ticket attributes are checked before creating a ticket.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection'],
  },
  state:       [],
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Warning title'),
  name:        'ticket_duplicate_detection_title',
  area:        'Web::TicketDuplicateDetection',
  description: __('Defines the warning title that is shown when a matching ticket is present.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection'],
  },
  state:       __('Similar tickets found'),
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Warning message'),
  name:        'ticket_duplicate_detection_body',
  area:        'Web::TicketDuplicateDetection',
  description: __('Defines the warning message that is shown when a matching ticket is present.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection'],
  },
  state:       __('Tickets with the same attributes were found.'),
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Show to user roles'),
  name:        'ticket_duplicate_detection_role_ids',
  area:        'Web::TicketDuplicateDetection',
  description: __('Defines which user roles will receive a warning in case of matching tickets.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection'],
  },
  state:       [2],
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Show matching tickets in the warning'),
  name:        'ticket_duplicate_detection_show_tickets',
  area:        'Web::TicketDuplicateDetection',
  description: __('Defines whether the matching tickets are shown in case of already existing tickets.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection'],
  },
  state:       true,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Permission level for looking up tickets'),
  name:        'ticket_duplicate_detection_permission_level',
  area:        'Web::TicketDuplicateDetection',
  description: __('Defines the permission level used for lookups.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection'],
  },
  state:       'user',
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Match tickets in following states'),
  name:        'ticket_duplicate_detection_search',
  area:        'Web::TicketDuplicateDetection',
  description: __('Defines the ticket states used for lookups.'),
  options:     {
    form: [
      {},
    ],
  },
  state:       'all',
  preferences: {
    authentication: true,
    permission:     ['admin.ticket_duplicate_detection']
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Ticket Number ignore system_id'),
  name:        'ticket_number_ignore_system_id',
  area:        'Ticket::Core',
  description: '-',
  options:     {
    form: [
      {
        display: __('Ignore system_id'),
        null:    true,
        name:    'ticket_number_ignore_system_id',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    permission: ['admin.ticket'],
    hidden:     true,
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Recursive Ticket Triggers'),
  name:        'ticket_trigger_recursive',
  area:        'Ticket::Core',
  description: __('Activate the recursive processing of ticket triggers.'),
  options:     {
    form: [
      {
        display: __('Recursive Ticket Triggers'),
        null:    true,
        name:    'ticket_trigger_recursive',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    permission: ['admin.ticket'],
    hidden:     true,
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Trigger Loop Protection Articles per Ticket'),
  name:        'ticket_trigger_loop_protection_articles_per_ticket',
  area:        'Ticket::Core',
  description: __('Defines the configuration how many articles can be created in a minute range per ticket.'),
  options:     {},
  state:       {
    10  => 10,
    30  => 15,
    60  => 25,
    180 => 50,
    600 => 100,
  },
  preferences: {
    permission: ['admin.ticket'],
    hidden:     true,
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Trigger Loop Protection Articles Total'),
  name:        'ticket_trigger_loop_protection_articles_total',
  area:        'Ticket::Core',
  description: __('Defines the configuration how many articles can be created in a minute range globally.'),
  options:     {},
  state:       {
    10  => 30,
    30  => 60,
    60  => 120,
    180 => 240,
    600 => 360,
  },
  preferences: {
    permission: ['admin.ticket'],
    hidden:     true,
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Maximum Recursive Ticket Triggers Depth'),
  name:        'ticket_trigger_recursive_max_loop',
  area:        'Ticket::Core',
  description: __('Maximum number of recursively executed triggers.'),
  options:     {
    form: [
      {
        display: __('Recursive Ticket Triggers'),
        null:    true,
        name:    'ticket_trigger_recursive_max_loop',
        tag:     'select',
        options: {
          1  => ' 1',
          2  => ' 2',
          3  => ' 3',
          4  => ' 4',
          5  => ' 5',
          6  => ' 6',
          7  => ' 7',
          8  => ' 8',
          9  => ' 9',
          10 => '10',
          11 => '11',
          12 => '12',
          13 => '13',
          14 => '14',
          15 => '15',
          16 => '16',
          17 => '17',
          18 => '18',
          19 => '19',
          20 => '20',
        },
      },
    ],
  },
  state:       10,
  preferences: {
    permission: ['admin.ticket'],
    hidden:     true,
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Enable Ticket creation'),
  name:        'customer_ticket_create',
  area:        'CustomerWeb::Base',
  description: __('Defines if a customer can create tickets via the web interface.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'customer_ticket_create',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    authentication: true,
    permission:     ['admin.channel_web'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Group selection for Ticket creation'),
  name:        'customer_ticket_create_group_ids',
  area:        'CustomerWeb::Base',
  description: __('Defines groups for which a customer can create tickets via web interface. No selection means all groups are available.'),
  options:     {
    form: [
      {
        display:  '',
        null:     true,
        name:     'group_ids',
        tag:      'tree_select',
        multiple: true,
        relation: 'Group',
      },
    ],
  },
  state:       nil,
  preferences: {
    authentication: true,
    permission:     ['admin.channel_web'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Tab behaviour after ticket action'),
  name:        'ticket_secondary_action',
  area:        'CustomerWeb::Base',
  description: __('Defines the tab behaviour after a ticket action.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_secondary_action',
        tag:     'boolean',
        options: {
          'closeTab'              => __('Close tab'),
          'closeTabOnTicketClose' => __('Close tab on ticket close'),
          'closeNextInOverview'   => __('Next in overview'),
          'stayOnTab'             => __('Stay on tab'),
        },
      },
    ],
  },
  state:       'stayOnTab',
  preferences: {
    authentication: true,
    permission:     ['admin.channel_web'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Enable Ticket creation'),
  name:        'form_ticket_create',
  area:        'Form::Base',
  description: __('Defines if tickets can be created via web form.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'form_ticket_create',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend:    false,
)

group = Group.where(active: true).first
if !group
  group = Group.first
end
group_id = 1
if group
  group_id = group.id
end
Setting.create_if_not_exists(
  title:       __('Group selection for ticket creation'),
  name:        'form_ticket_create_group_id',
  area:        'Form::Base',
  description: __('Defines the group of tickets created via web form.'),
  options:     {
    form: [
      {
        display:  '',
        null:     true,
        name:     'form_ticket_create_group_id',
        tag:      'select',
        relation: 'Group',
      },
    ],
  },
  state:       group_id,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend:    false,
)

Setting.create_if_not_exists(
  title:       __('Limit tickets by IP per hour'),
  name:        'form_ticket_create_by_ip_per_hour',
  area:        'Form::Base',
  description: __('Defines a limit for how many tickets can be created via web form from one IP address per hour.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'form_ticket_create_by_ip_per_hour',
        tag:     'input',
      },
    ],
  },
  state:       20,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Limit tickets by IP per day'),
  name:        'form_ticket_create_by_ip_per_day',
  area:        'Form::Base',
  description: __('Defines a limit for how many tickets can be created via web form from one IP address per day.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'form_ticket_create_by_ip_per_day',
        tag:     'input',
      },
    ],
  },
  state:       240,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Limit tickets per day'),
  name:        'form_ticket_create_per_day',
  area:        'Form::Base',
  description: __('Defines a limit for how many tickets can be created via web form per day.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'form_ticket_create_per_day',
        tag:     'input',
      },
    ],
  },
  state:       5000,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend:    false,
)

Setting.create_if_not_exists(
  title:       __('Ticket Subject Size'),
  name:        'ticket_subject_size',
  area:        'Email::Base',
  description: __('Max. length of the subject in an email reply.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'ticket_subject_size',
        tag:     'input',
      },
    ],
  },
  state:       '110',
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Ticket Subject Reply'),
  name:        'ticket_subject_re',
  area:        'Email::Base',
  description: __('The text at the beginning of the subject in an email reply, e.g. RE, AW, or AS.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_subject_re',
        tag:     'input',
      },
    ],
  },
  state:       'RE',
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Ticket Subject Forward'),
  name:        'ticket_subject_fwd',
  area:        'Email::Base',
  description: __('The text at the beginning of the subject in an email forward, e. g. FWD.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ticket_subject_fwd',
        tag:     'input',
      },
    ],
  },
  state:       'FWD',
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Sender Format'),
  name:        'ticket_define_email_from',
  area:        'Email::Base',
  description: __('Defines how the From field of emails (sent from answers and email tickets) should look like.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'ticket_define_email_from',
        tag:       'select',
        options:   {
          SystemAddressName:          __('System Address Display Name'),
          AgentNameSystemAddressName: __('Agent Name + FromSeparator + System Address Display Name'),
          AgentName:                  __('Agent Name'),
        },
        translate: true,
      },
    ],
  },
  state:       'AgentNameSystemAddressName',
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Sender Format Separator'),
  name:        'ticket_define_email_from_separator',
  area:        'Email::Base',
  description: __('Defines the separator between the agent\'s real name and the given group email address.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'ticket_define_email_from_separator',
        tag:     'input',
      },
    ],
  },
  state:       'via',
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Maximum Email Size'),
  name:        'postmaster_max_size',
  area:        'Email::Base',
  description: __('Defines the maximum accepted email size in MB.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'postmaster_max_size',
        tag:     'select',
        options: {
          1   => '  1',
          2   => '  2',
          3   => '  3',
          4   => '  4',
          5   => '  5',
          6   => '  6',
          7   => '  7',
          8   => '  8',
          9   => '  9',
          10  => ' 10',
          15  => ' 15',
          20  => ' 20',
          25  => ' 25',
          30  => ' 30',
          35  => ' 35',
          40  => ' 40',
          45  => ' 45',
          50  => ' 50',
          60  => ' 60',
          70  => ' 70',
          80  => ' 80',
          90  => ' 90',
          100 => '100',
          125 => '125',
          150 => '150',
        },
      },
    ],
  },
  state:       10,
  preferences: {
    online_service_disable: true,
    permission:             ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Additional follow-up detection'),
  name:        'postmaster_follow_up_search_in',
  area:        'Email::Base',
  description: __('By default, the follow-up check is done via the subject of an email. This setting lets you add more fields for which the follow-up check will be executed.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'postmaster_follow_up_search_in',
        tag:       'checkbox',
        options:   {
          'references'         => __('References - Search for follow-up also in In-Reply-To or References headers.'),
          'body'               => __('Body - Search for follow-up also in mail body.'),
          'attachment'         => __('Attachment - Search for follow-up also in attachments.'),
          'subject_references' => __('Subject & References - Additional search for same article subject and same message ID in references header if no follow-up was recognized using default settings.'),
        },
        translate: true,
      },
    ],
  },
  state:       ['subject_references'],
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Sender based on Reply-To header'),
  name:        'postmaster_sender_based_on_reply_to',
  area:        'Email::Base',
  description: __('Set/overwrite sender/from of email based on "Reply-To" header. Useful to set correct customer if email is received from a third-party system on behalf of a customer.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'postmaster_sender_based_on_reply_to',
        tag:       'select',
        options:   {
          ''                                     => '-',
          'as_sender_of_email'                   => __('Take Reply-To header as sender/from of email.'),
          'as_sender_of_email_use_from_realname' => __('Take Reply-To header as sender/from of email and use the real name of origin from.'),
        },
        translate: true,
      },
    ],
  },
  state:       [],
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Customer selection based on sender and receiver list'),
  name:        'postmaster_sender_is_agent_search_for_customer',
  area:        'Email::Base',
  description: __('If the sender is an agent, set the first user in the recipient list as the customer.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'postmaster_sender_is_agent_search_for_customer',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    permission: ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Send postmaster mail if mail too large'),
  name:        'postmaster_send_reject_if_mail_too_large',
  area:        'Email::Base',
  description: __('Send postmaster reject mail to sender of mail if mail is too large.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'postmaster_send_reject_if_mail_too_large',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    online_service_disable: true,
    permission:             ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Notification Sender'),
  name:        'notification_sender',
  area:        'Email::Base',
  description: __('Defines the sender of email notifications.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'notification_sender',
        tag:     'input',
      },
    ],
  },
  state:       '#{config.product_name} <noreply@#{config.fqdn}>', # rubocop:disable Lint/InterpolationCheck
  preferences: {
    online_service_disable: true,
    permission:             ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Block Notifications'),
  name:        'send_no_auto_response_reg_exp',
  area:        'Email::Base',
  description: __('If this regex matches, no notification will be sent by the sender.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'send_no_auto_response_reg_exp',
        tag:     'input',
      },
    ],
  },
  state:       '(mailer-daemon|postmaster|abuse|root|noreply|noreply.+?|no-reply|no-reply.+?)@.+?',
  preferences: {
    online_service_disable: true,
    permission:             ['admin.channel_email', 'admin.channel_google', 'admin.channel_microsoft365', 'admin.channel_microsoft_graph'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('BCC address for all outgoing emails'),
  name:        'system_bcc',
  area:        'Email::Enhanced',
  description: __('To archive all outgoing emails from Zammad to external, you can store a BCC email address here.'),
  options:     {},
  state:       '',
  preferences: { online_service_disable: true },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('API Token Access'),
  name:        'api_token_access',
  area:        'API::Base',
  description: __('Enable REST API using tokens (not username/email address and password). Each user needs to create its own access tokens in user profile.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'api_token_access',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    permission: ['admin.api'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('API Password Access'),
  name:        'api_password_access',
  area:        'API::Base',
  description: __('Enable REST API access using the username/email address and password for the authentication user.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'api_password_access',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    permission: ['admin.api'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Monitoring Token'),
  name:        'monitoring_token',
  area:        'HealthCheck::Base',
  description: __('Token for monitoring.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'monitoring_token',
        tag:     'input',
      },
    ],
  },
  state:       ENV['MONITORING_TOKEN'] || SecureRandom.urlsafe_base64(40),
  preferences: {
    permission: ['admin.monitoring'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Enable Chat'),
  name:        'chat',
  area:        'Chat::Base',
  description: __('Enable/disable online chat.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'chat',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    trigger:    ['menu:render', 'chat:rerender'],
    permission: ['admin.channel_chat'],
  },
  state:       false,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Agent idle timeout'),
  name:        'chat_agent_idle_timeout',
  area:        'Chat::Extended',
  description: __('Idle timeout in seconds until agent is set offline automatically.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'chat_agent_idle_timeout',
        tag:     'input',
      },
    ],
  },
  state:       '120',
  preferences: {
    permission: ['admin.channel_chat'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Default Screen'),
  name:        'default_controller',
  area:        'Core',
  description: __('Defines the default screen.'),
  options:     {},
  state:       '#dashboard',
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Elasticsearch Endpoint URL'),
  name:        'es_url',
  area:        'SearchIndex::Elasticsearch',
  description: __('Defines endpoint of Elasticsearch.'),
  state:       '',
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Endpoint User'),
  name:        'es_user',
  area:        'SearchIndex::Elasticsearch',
  description: __('Defines HTTP basic auth user of Elasticsearch.'),
  state:       '',
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Endpoint Password'),
  name:        'es_password',
  area:        'SearchIndex::Elasticsearch',
  description: __('Defines HTTP basic auth password of Elasticsearch.'),
  state:       '',
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Endpoint Index'),
  name:        'es_index',
  area:        'SearchIndex::Elasticsearch',
  description: __('Defines Elasticsearch index name.'),
  state:       'zammad',
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch SSL verification'),
  name:        'es_ssl_verify',
  area:        'SearchIndex::Elasticsearch',
  description: __('Defines Elasticsearch SSL verification.'),
  state:       true,
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Attachment Extensions'),
  name:        'es_attachment_ignore',
  area:        'SearchIndex::Elasticsearch',
  description: __('Defines attachment extensions which will be ignored by Elasticsearch.'),
  state:       [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe', '.box', '.mbox' ],
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Attachment Size'),
  name:        'es_attachment_max_size_in_mb',
  area:        'SearchIndex::Elasticsearch',
  description: __('Define max. attachment size for Elasticsearch.'),
  state:       10,
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Total Payload Size'),
  name:        'es_total_max_size_in_mb',
  area:        'SearchIndex::Elasticsearch',
  description: __('Define max. payload size for Elasticsearch.'),
  state:       300,
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Pipeline Name'),
  name:        'es_pipeline',
  area:        'SearchIndex::Elasticsearch',
  description: __('Define pipeline name for Elasticsearch.'),
  state:       '',
  preferences: { online_service_disable: true },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Elasticsearch Model Configuration'),
  name:        'es_model_settings',
  area:        'SearchIndex::Elasticsearch',
  description: __('Define model configuration for Elasticsearch.'),
  state:       {},
  preferences: { online_service_disable: true },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import Mode'),
  name:        'import_mode',
  area:        'Import::Base',
  description: __('Puts Zammad into import mode (disables some triggers).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'import_mode',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Import Backend'),
  name:        'import_backend',
  area:        'Import::Base::Internal',
  description: __('Set backend which is being used for import.'),
  options:     {},
  state:       '',
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Ignore Escalation/SLA Information'),
  name:        'import_ignore_sla',
  area:        'Import::Base',
  description: __('Ignore escalation/SLA information for import.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'import_ignore_sla',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import Endpoint'),
  name:        'import_otrs_endpoint',
  area:        'Import::OTRS',
  description: __('Defines an OTRS endpoint to import users, tickets, states, and articles.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_otrs_endpoint',
        tag:     'input',
      },
    ],
  },
  state:       'http://otrs_host/otrs',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Import Key'),
  name:        'import_otrs_endpoint_key',
  area:        'Import::OTRS',
  description: __('Defines OTRS endpoint authentication key.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_otrs_endpoint_key',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import User for HTTP basic authentication'),
  name:        'import_otrs_user',
  area:        'Import::OTRS',
  description: __('Defines HTTP basic authentication user (only if OTRS is protected via HTTP basic auth).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'import_otrs_user',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import Password for HTTP basic authentication'),
  name:        'import_otrs_password',
  area:        'Import::OTRS',
  description: __('Defines HTTP basic authentication password (only if OTRS is protected via HTTP basic auth).'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'import_otrs_password',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import Endpoint'),
  name:        'import_zendesk_endpoint',
  area:        'Import::Zendesk',
  description: __('Defines a Zendesk endpoint to import users, tickets, states, and articles.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_zendesk_endpoint',
        tag:     'input',
      },
    ],
  },
  state:       'https://yours.zendesk.com/api/v2',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Import API key for requesting the Zendesk API'),
  name:        'import_zendesk_endpoint_key',
  area:        'Import::Zendesk',
  description: __('Defines Zendesk endpoint authentication API key.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_zendesk_endpoint_key',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import User for requesting the Zendesk API'),
  name:        'import_zendesk_endpoint_username',
  area:        'Import::Zendesk',
  description: __('Defines Zendesk endpoint authentication user.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'import_zendesk_endpoint_username',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import Endpoint'),
  name:        'import_freshdesk_endpoint',
  area:        'Import::Freshdesk',
  description: __('Defines a Freshdesk endpoint to import users, tickets, states, and articles.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_freshdesk_endpoint',
        tag:     'input',
      },
    ],
  },
  state:       'https://yours.freshdesk.com/api/v2',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Import API key for requesting the Freshdesk API'),
  name:        'import_freshdesk_endpoint_key',
  area:        'Import::Freshdesk',
  description: __('Defines Freshdesk endpoint authentication API key.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_freshdesk_endpoint_key',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import Endpoint'),
  name:        'import_kayako_endpoint',
  area:        'Import::Kayako',
  description: __('Defines a Kayako endpoint to import users, tickets, states, and articles.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_kayako_endpoint',
        tag:     'input',
      },
    ],
  },
  state:       'https://yours.kayako.com/api/v1',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Import User for requesting the Kayako API'),
  name:        'import_kayako_endpoint_username',
  area:        'Import::Kayako',
  description: __('Defines Kayako endpoint authentication user.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_kayako_endpoint_username',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Import Password for requesting the Kayako API'),
  name:        'import_kayako_endpoint_password',
  area:        'Import::Kayako',
  description: __('Defines Kayako endpoint authentication password.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'import_kayako_endpoint_password',
        tag:     'input',
      },
    ],
  },
  state:       '',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Import Backends'),
  name:        'import_backends',
  area:        'Import',
  description: __('A list of active import backends that gets scheduled automatically.'),
  options:     {},
  state:       ['Import::Ldap', 'Import::Exchange'],
  preferences: {
    permission: ['admin'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Sequencer log level'),
  name:        'sequencer_log_level',
  area:        'Core',
  description: __('Defines the log levels for various logging actions of the Sequencer.'),
  options:     {},
  state:       {
    sequence: {
      start_finish: :debug,
      unit:         :debug,
      result:       :debug,
    },
    state:    {
      optional:                    :debug,
      set:                         :debug,
      get:                         :debug,
      attribute_initialization:    {
        start_finish: :debug,
        attributes:   :debug,
      },
      parameter_initialization:    {
        parameters:   :debug,
        start_finish: :debug,
        unused:       :debug,
      },
      expectations_initialization: :debug,
      cleanup:                     {
        start_finish: :debug,
        remove:       :debug,
      }
    }
  },
  frontend:    false,
)

Setting.create_if_not_exists(
  title:       __('Time Accounting'),
  name:        'time_accounting',
  area:        'Web::Base',
  description: __('Enable time accounting.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'time_accounting',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.time_accounting'],
  },
  state:       false,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Time Accounting Selector'),
  name:        'time_accounting_selector',
  area:        'Web::Base',
  description: __('Show time accounting dialog when updating matching tickets.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.time_accounting'],
  },
  state:       {},
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Time Accounting Unit'),
  name:        'time_accounting_unit',
  area:        'Web::Base',
  description: __('Defines the unit to be shown next to the time accounting input field.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.time_accounting'],
  },
  state:       '',
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Time Accounting Custom Unit'),
  name:        'time_accounting_unit_custom',
  area:        'Web::Base',
  description: __('Defines the custom unit to be shown next to the time accounting input field.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.time_accounting'],
  },
  state:       '',
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Time Accounting Types'),
  name:        'time_accounting_types',
  area:        'Web::Base',
  description: __('Defines if the time accounting types are enabled.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.time_accounting'],
  },
  state:       false,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Time Accounting Default Type'),
  name:        'time_accounting_type_default',
  area:        'Web::Base',
  description: __('Defines the default time accounting type.'),
  options:     {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.time_accounting'],
  },
  state:       '',
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('New Tags'),
  name:        'tag_new',
  area:        'Web::Base',
  description: __('Allow users to create new tags.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'tag_new',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.tag'],
  },
  state:       true,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Default calendar tickets subscriptions'),
  name:        'defaults_calendar_subscriptions_tickets',
  area:        'Defaults::CalendarSubscriptions',
  description: __('Defines the default calendar tickets subscription settings.'),
  options:     {},
  state:       {
    escalation: {
      own:          true,
      not_assigned: false,
    },
    new_open:   {
      own:          true,
      not_assigned: false,
    },
    pending:    {
      own:          true,
      not_assigned: false,
    }
  },
  preferences: {
    authentication: true,
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0005_postmaster_filter_trusted',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to remove X-Zammad headers from untrustworthy sources.'),
  options:     {},
  state:       'Channel::Filter::Trusted',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0006_postmaster_filter_auto_response_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify auto responses to prevent auto replies from Zammad.'),
  options:     {},
  state:       'Channel::Filter::AutoResponseCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0007_postmaster_filter_follow_up_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify follow-ups (based on admin settings).'),
  options:     {},
  state:       'Channel::Filter::FollowUpCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0008_postmaster_filter_follow_up_merged',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify follow-up ticket for merged tickets.'),
  options:     {},
  state:       'Channel::Filter::FollowUpMerged',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0009_postmaster_filter_follow_up_assignment',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to set the owner (based on group follow up assignment).'),
  options:     {},
  state:       'Channel::Filter::FollowUpAssignment',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0011_postmaster_sender_based_on_reply_to',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to set the sender/from of emails based on reply-to header.'),
  options:     {},
  state:       'Channel::Filter::ReplyToBasedSender',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Define postmaster filter.'),
  name:        '0018_postmaster_import_archive',
  area:        'Postmaster::PreFilter',
  description: __('Define postmaster filter to import archive mailboxes.'),
  options:     {},
  state:       'Channel::Filter::ImportArchive',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0012_postmaster_filter_sender_is_system_address',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to check if email has been created by Zammad itself and will set the article sender.'),
  options:     {},
  state:       'Channel::Filter::SenderIsSystemAddress',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0014_postmaster_filter_own_notification_loop_detection',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to check if the email is a self-created notification email, then ignore it to prevent email loops.'),
  options:     {},
  state:       'Channel::Filter::OwnNotificationLoopDetection',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0015_postmaster_filter_identify_sender',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify sender user.'),
  options:     {},
  state:       'Channel::Filter::IdentifySender',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0016_postmaster_filter_secure_mailing',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to handle secure mailing.'),
  options:     {},
  state:       'Channel::Filter::SecureMailing',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0030_postmaster_filter_out_of_office_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify out-of-office emails for follow-up detection and keeping current ticket state.'),
  options:     {},
  state:       'Channel::Filter::OutOfOfficeCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0200_postmaster_filter_follow_up_possible_check',
  area:        'Postmaster::PreFilter',
  description: __('Define postmaster filter to check if follow-ups get created (based on admin settings).'),
  options:     {},
  state:       'Channel::Filter::FollowUpPossibleCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0900_postmaster_filter_bounce_follow_up_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify postmaster bounces; and handles them as follow-up of the original tickets'),
  options:     {},
  state:       'Channel::Filter::BounceFollowUpCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0950_postmaster_filter_bounce_delivery_permanent_failed',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify postmaster bounces; and disables sending notification if delivery fails permanently.'),
  options:     {},
  state:       'Channel::Filter::BounceDeliveryPermanentFailed',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0955_postmaster_filter_bounce_delivery_temporary_failed',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify postmaster bounces; and reopens tickets if delivery fails permanently.'),
  options:     {},
  state:       'Channel::Filter::BounceDeliveryTemporaryFailed',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '1000_postmaster_filter_database_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter for filters managed via admin interface.'),
  options:     {},
  state:       'Channel::Filter::Database',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '5000_postmaster_filter_icinga',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to manage Icinga (http://www.icinga.org) emails.'),
  options:     {},
  state:       'Channel::Filter::Icinga',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '5100_postmaster_filter_nagios',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to manage Nagios (http://www.nagios.org) emails.'),
  options:     {},
  state:       'Channel::Filter::Nagios',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '5300_postmaster_filter_monit',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to manage Monit (https://mmonit.com/monit/) emails.'),
  options:     {},
  state:       'Channel::Filter::Monit',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '5400_postmaster_filter_service_now_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify ServiceNow mails for correct follow-ups.'),
  options:     {},
  state:       'Channel::Filter::ServiceNowCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '5401_postmaster_filter_service_now_check',
  area:        'Postmaster::PostFilter',
  description: __('Defines postmaster filter to identify ServiceNow mails for correct follow-ups.'),
  options:     {},
  state:       'Channel::Filter::ServiceNowCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '5400_postmaster_filter_jira_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify Jira mails for correct follow-ups.'),
  options:     {},
  state:       'Channel::Filter::JiraCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '5401_postmaster_filter_jira_check',
  area:        'Postmaster::PostFilter',
  description: __('Defines postmaster filter to identify Jira mails for correct follow-ups.'),
  options:     {},
  state:       'Channel::Filter::JiraCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Define postmaster filter.'),
  name:        '5500_postmaster_internal_article_check',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter which sets the articles visibility to internal if it is a rely to an internal article or the last outgoing email is internal.'),
  options:     {},
  state:       'Channel::Filter::InternalArticleCheck',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Icinga integration'),
  name:        'icinga_integration',
  area:        'Integration::Switch',
  description: __('Defines if Icinga (http://www.icinga.org) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'icinga_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       1,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Sender'),
  name:        'icinga_sender',
  area:        'Integration::Icinga',
  description: __('Defines the sender email address of Icinga emails.'),
  options:     {
    form: [
      {
        display:     '',
        null:        false,
        name:        'icinga_sender',
        tag:         'input',
        placeholder: 'icinga@monitoring.example.com',
      },
    ],
  },
  state:       'icinga@monitoring.example.com',
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Auto close'),
  name:        'icinga_auto_close',
  area:        'Integration::Icinga',
  description: __('Defines if tickets should be closed if service is recovered.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'icinga_auto_close',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       3,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Auto-close state'),
  name:        'icinga_auto_close_state_id',
  area:        'Integration::Icinga',
  description: __('Defines the state of auto-closed tickets.'),
  options:     {
    form: [
      {
        display:  '',
        null:     false,
        name:     'icinga_auto_close_state_id',
        tag:      'select',
        relation: 'TicketState',
      },
    ],
  },
  state:       4,
  preferences: {
    prio:       4,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Nagios integration'),
  name:        'nagios_integration',
  area:        'Integration::Switch',
  description: __('Defines if Nagios (http://www.nagios.org) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'nagios_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       1,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Sender'),
  name:        'nagios_sender',
  area:        'Integration::Nagios',
  description: __('Defines the sender email address of Nagios emails.'),
  options:     {
    form: [
      {
        display:     '',
        null:        false,
        name:        'nagios_sender',
        tag:         'input',
        placeholder: 'nagios@monitoring.example.com',
      },
    ],
  },
  state:       'nagios@monitoring.example.com',
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Auto close'),
  name:        'nagios_auto_close',
  area:        'Integration::Nagios',
  description: __('Defines if tickets should be closed if service is recovered.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'nagios_auto_close',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       3,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Auto-close state'),
  name:        'nagios_auto_close_state_id',
  area:        'Integration::Nagios',
  description: __('Defines the state of auto-closed tickets.'),
  options:     {
    form: [
      {
        display:  '',
        null:     false,
        name:     'nagios_auto_close_state_id',
        tag:      'select',
        relation: 'TicketState',
      },
    ],
  },
  state:       4,
  preferences: {
    prio:       4,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Checkmk integration'),
  name:        'check_mk_integration',
  area:        'Integration::Switch',
  description: __('Defines if Checkmk (https://checkmk.com/) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'check_mk_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       1,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Group'),
  name:        'check_mk_group_id',
  area:        'Integration::CheckMK',
  description: __('Defines the group of created tickets.'),
  options:     {
    form: [
      {
        display:  '',
        null:     false,
        name:     'check_mk_group_id',
        tag:      'select',
        relation: 'Group',
      },
    ],
  },
  state:       1,
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Auto close'),
  name:        'check_mk_auto_close',
  area:        'Integration::CheckMK',
  description: __('Defines if tickets should be closed if service is recovered.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'check_mk_auto_close',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       3,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Auto-close state'),
  name:        'check_mk_auto_close_state_id',
  area:        'Integration::CheckMK',
  description: __('Defines the state of auto-closed tickets.'),
  options:     {
    form: [
      {
        display:  '',
        null:     false,
        name:     'check_mk_auto_close_state_id',
        tag:      'select',
        relation: 'TicketState',
      },
    ],
  },
  state:       4,
  preferences: {
    prio:       4,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Checkmk token'),
  name:        'check_mk_token',
  area:        'Core',
  description: __('Defines the Checkmk token for allowing updates.'),
  options:     {},
  state:       ENV['CHECK_MK_TOKEN'] || SecureRandom.hex(16),
  preferences: {
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Monit integration'),
  name:        'monit_integration',
  area:        'Integration::Switch',
  description: __('Defines if Monit (https://mmonit.com/monit/) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'monit_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       1,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Sender'),
  name:        'monit_sender',
  area:        'Integration::Monit',
  description: __('Defines the sender email address of the service emails.'),
  options:     {
    form: [
      {
        display:     '',
        null:        false,
        name:        'monit_sender',
        tag:         'input',
        placeholder: 'monit@monitoring.example.com',
      },
    ],
  },
  state:       'monit@monitoring.example.com',
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Auto close'),
  name:        'monit_auto_close',
  area:        'Integration::Monit',
  description: __('Defines if tickets should be closed if service is recovered.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'monit_auto_close',
        tag:       'boolean',
        options:   {
          true  => 'yes',
          false => 'no',
        },
        translate: true,
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       3,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Auto-close state'),
  name:        'monit_auto_close_state_id',
  area:        'Integration::Monit',
  description: __('Defines the state of auto-closed tickets.'),
  options:     {
    form: [
      {
        display:   '',
        null:      false,
        name:      'monit_auto_close_state_id',
        tag:       'select',
        relation:  'TicketState',
        translate: true,
      },
    ],
  },
  state:       4,
  preferences: {
    prio:       4,
    permission: ['admin.integration'],
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('LDAP integration'),
  name:        'ldap_integration',
  area:        'Integration::Switch',
  description: __('Defines if LDAP is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ldap_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Exchange config'),
  name:        'exchange_config',
  area:        'Integration::Exchange',
  description: __('Defines the Exchange config.'),
  options:     {},
  state:       {},
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Exchange OAuth'),
  name:        'exchange_oauth',
  area:        'Integration::Exchange',
  description: __('Defines the Exchange OAuth config.'),
  options:     {},
  state:       {},
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Exchange integration'),
  name:        'exchange_integration',
  area:        'Integration::Switch',
  description: __('Defines if Exchange is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'exchange_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('i-doit integration'),
  name:        'idoit_integration',
  area:        'Integration::Switch',
  description: __('Defines if the i-doit (https://www.i-doit.org/) integration is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'idoit_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('i-doit config'),
  name:        'idoit_config',
  area:        'Integration::Idoit',
  description: __('Defines the i-doit config.'),
  options:     {},
  state:       {},
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('GitLab integration'),
  name:        'gitlab_integration',
  area:        'Integration::Switch',
  description: __('Defines if the GitLab (http://www.gitlab.com) integration is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'gitlab_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('GitLab config'),
  name:        'gitlab_config',
  area:        'Integration::GitLab',
  description: __('Stores the GitLab configuration.'),
  options:     {},
  state:       {
    endpoint: 'https://gitlab.com/api/graphql',
  },
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('GitHub integration'),
  name:        'github_integration',
  area:        'Integration::Switch',
  description: __('Defines if the GitHub (http://www.github.com) integration is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'github_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('GitHub config'),
  name:        'github_config',
  area:        'Integration::GitHub',
  description: __('Stores the GitHub configuration.'),
  options:     {},
  state:       {
    endpoint: 'https://api.github.com/graphql',
  },
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Defines sync transaction backend.'),
  name:        '0100_trigger',
  area:        'Transaction::Backend::Sync',
  description: __('Defines the transaction backend to execute triggers.'),
  options:     {},
  state:       'Transaction::Trigger',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines transaction backend.'),
  name:        '0100_notification',
  area:        'Transaction::Backend::Async',
  description: __('Defines the transaction backend to send agent notifications.'),
  options:     {},
  state:       'Transaction::Notification',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines transaction backend.'),
  name:        '1000_signature_detection',
  area:        'Transaction::Backend::Async',
  description: __('Defines the transaction backend to detect customer signatures in emails.'),
  options:     {},
  state:       'Transaction::SignatureDetection',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines transaction backend.'),
  name:        '6000_slack_webhook',
  area:        'Transaction::Backend::Async',
  description: __('Defines the transaction backend which posts messages to Slack (http://www.slack.com).'),
  options:     {},
  state:       'Transaction::Slack',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Slack integration'),
  name:        'slack_integration',
  area:        'Integration::Switch',
  description: __('Defines if Slack (http://www.slack.org) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'slack_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       1,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Slack config'),
  name:        'slack_config',
  area:        'Integration::Slack',
  description: __('Defines the Slack config.'),
  options:     {},
  state:       {
    items: []
  },
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('sipgate.io integration'),
  name:        'sipgate_integration',
  area:        'Integration::Switch',
  description: __('Defines if sipgate.io (http://www.sipgate.io) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'sipgate_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    trigger:        ['menu:render', 'cti:reload'],
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('sipgate.io Token'),
  name:        'sipgate_token',
  area:        'Integration::Sipgate',
  description: __('Token for Sipgate.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'sipgate_token',
        tag:     'input',
      },
    ],
  },
  state:       ENV['SIPGATE_TOKEN'] || SecureRandom.urlsafe_base64(20),
  preferences: {
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('sipgate.io config'),
  name:        'sipgate_config',
  area:        'Integration::Sipgate',
  description: __('Defines the sipgate.io config.'),
  options:     {},
  state:       { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('sipgate.io alternative FQDN'),
  name:        'sipgate_alternative_fqdn',
  area:        'Integration::Sipgate::Expert',
  description: __('Alternative FQDN for callbacks if you operate Zammad in an internal network.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'sipgate_alternative_fqdn',
        tag:     'input',
      },
    ],
  },
  state:       '',
  preferences: {
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('CTI integration'),
  name:        'cti_integration',
  area:        'Integration::Switch',
  description: __('Defines if generic CTI integration is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'cti_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    trigger:        ['menu:render', 'cti:reload'],
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('CTI config'),
  name:        'cti_config',
  area:        'Integration::Cti',
  description: __('Defines the CTI config.'),
  options:     {},
  state:       { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('CTI Token'),
  name:        'cti_token',
  area:        'Integration::Cti',
  description: __('Token for CTI.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'cti_token',
        tag:     'input',
      },
    ],
  },
  state:       ENV['CTI_TOKEN'] || SecureRandom.urlsafe_base64(20),
  preferences: {
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('CTI customer last activity'),
  name:        'cti_customer_last_activity',
  area:        'Integration::Cti',
  description: __('Defines the duration of customer activity (in seconds) on a call until the user profile dialog is shown.'),
  options:     {},
  state:       30.days,
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Placetel integration'),
  name:        'placetel_integration',
  area:        'Integration::Switch',
  description: __('Defines if Placetel (http://www.placetel.de) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'placetel_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    trigger:        ['menu:render', 'cti:reload'],
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)
Setting.create_if_not_exists(
  title:       __('Placetel config'),
  name:        'placetel_config',
  area:        'Integration::Placetel',
  description: __('Defines the Placetel config.'),
  options:     {},
  state:       { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
    cache:      ['placetelGetVoipUsers'],
  },
  frontend:    false,
)
Setting.create_if_not_exists(
  title:       __('Placetel Token'),
  name:        'placetel_token',
  area:        'Integration::Placetel',
  description: __('Defines the token for Placetel.'),
  options:     {
    form: [
      {
        display: '',
        null:    false,
        name:    'placetel_token',
        tag:     'input',
      },
    ],
  },
  state:       ENV['PLACETEL_TOKEN'] || SecureRandom.urlsafe_base64(20),
  preferences: {
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Clearbit integration'),
  name:        'clearbit_integration',
  area:        'Integration::Switch',
  description: __('Defines if Clearbit (http://www.clearbit.com) is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'clearbit_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:       1,
    permission: ['admin.integration'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Clearbit config'),
  name:        'clearbit_config',
  area:        'Integration::Clearbit',
  description: __('Defines the Clearbit config.'),
  options:     {},
  state:       {},
  frontend:    false,
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
)
Setting.create_if_not_exists(
  title:       __('Defines transaction backend.'),
  name:        '9000_clearbit_enrichment',
  area:        'Transaction::Backend::Async',
  description: __('Defines the transaction backend which will enrich customer and organization information from Clearbit (http://www.clearbit.com).'),
  options:     {},
  state:       'Transaction::ClearbitEnrichment',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines transaction backend.'),
  name:        '9100_cti_caller_id_detection',
  area:        'Transaction::Backend::Async',
  description: __('Defines the transaction backend which detects caller IDs in objects and stores them for CTI lookups.'),
  options:     {},
  state:       'Transaction::CtiCallerIdDetection',
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('Defines transaction backend.'),
  name:        '9200_time_based_trigger',
  area:        'Transaction::Backend::Async',
  description: __('Defines the transaction backend which executes time based triggers.'),
  options:     {},
  state:       'Transaction::TimeBasedTrigger',
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Set agent limit'),
  name:        'system_agent_limit',
  area:        'Core::Online',
  description: __('Defines the agent limit.'),
  options:     {},
  state:       false,
  preferences: { online_service_disable: true },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('HTML Email CSS Font'),
  name:        'html_email_css_font',
  area:        'Core',
  description: __('Defines the CSS font information for HTML emails.'),
  options:     {},
  state:       "font-family:'Helvetica Neue', Helvetica, Arial, Geneva, sans-serif; font-size: 12px;",
  preferences: {
    permission: ['admin'],
  },
  frontend:    false
)
Setting.create_if_not_exists(
  title:       __('HTML Sanitizer Processing Timeout'),
  name:        'html_sanitizer_processing_timeout',
  area:        'Core',
  description: __('Defines processing timeout for the html sanitizer.'),
  options:     {},
  state:       20,
  preferences: {},
  frontend:    false
)

# add the dashboard stats backend for 'Stats::TicketWaitingTime'
Setting.create_if_not_exists(
  title:       __('Stats Backend'),
  name:        'Stats::TicketWaitingTime',
  area:        'Dashboard::Stats',
  description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
  options:     {},
  state:       'Stats::TicketWaitingTime',
  preferences: {
    permission: ['ticket.agent'],
    prio:       1,
  },
  frontend:    false
)

# add the dashboard stats backend for 'Stats::TicketEscalation'
Setting.create_if_not_exists(
  title:       __('Stats Backend'),
  name:        'Stats::TicketEscalation',
  area:        'Dashboard::Stats',
  description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
  options:     {},
  state:       'Stats::TicketEscalation',
  preferences: {
    permission: ['ticket.agent'],
    prio:       2,
  },
  frontend:    false
)

# add the dashboard stats backend for 'Stats::TicketChannelDistribution'
Setting.create_if_not_exists(
  title:       __('Stats Backend'),
  name:        'Stats::TicketChannelDistribution',
  area:        'Dashboard::Stats',
  description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
  options:     {},
  state:       'Stats::TicketChannelDistribution',
  preferences: {
    permission: ['ticket.agent'],
    prio:       3,
  },
  frontend:    false
)

# add the dashboard stats backend for 'Stats::TicketLoadMeasure'
Setting.create_if_not_exists(
  title:       __('Stats Backend'),
  name:        'Stats::TicketLoadMeasure',
  area:        'Dashboard::Stats',
  description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
  options:     {},
  state:       'Stats::TicketLoadMeasure',
  preferences: {
    permission: ['ticket.agent'],
    prio:       4,
  },
  frontend:    false
)

# add the dashboard stats backend for 'Stats::TicketInProcess'
Setting.create_if_not_exists(
  title:       __('Stats Backend'),
  name:        'Stats::TicketInProcess',
  area:        'Dashboard::Stats',
  description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
  options:     {},
  state:       'Stats::TicketInProcess',
  preferences: {
    permission: ['ticket.agent'],
    prio:       5,
  },
  frontend:    false
)

# add the dashboard stats backend for 'Stats::TicketReopen'
Setting.create_if_not_exists(
  title:       __('Stats Backend'),
  name:        'Stats::TicketReopen',
  area:        'Dashboard::Stats',
  description: __('Defines a dashboard stats backend that gets scheduled automatically.'),
  options:     {},
  state:       'Stats::TicketReopen',
  preferences: {
    permission: ['ticket.agent'],
    prio:       6,
  },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('Knowledge Base multilingual support'),
  name:        'kb_multi_lingual_support',
  area:        'Kb::Core',
  description: __('Support of multilingual Knowledge Base.'),
  options:     {},
  state:       true,
  preferences: { online_service_disable: true },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Knowledge Base active'),
  name:        'kb_active',
  area:        'Kb::Core',
  description: __('Defines if Knowledge Base navbar button is enabled.'),
  state:       true,
  preferences: {
    prio:           1,
    trigger:        ['menu:render'],
    authentication: true,
    permission:     ['admin.knowledge_base'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Knowledge Base active publicly'),
  name:        'kb_active_publicly',
  area:        'Kb::Core',
  description: __('Defines if Knowledge Base navbar button is enabled for users without Knowledge Base permission.'),
  state:       false,
  preferences: {
    prio:           1,
    trigger:        ['menu:render'],
    authentication: true,
    permission:     [],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Defines the timeframe during which a self-created note can be deleted.'),
  name:        'ui_ticket_zoom_article_delete_timeframe',
  area:        'UI::TicketZoomArticle',
  description: __("Set timeframe in seconds. If it's set to 0 you can delete notes without time limits"),
  options:     {},
  state:       600,
  preferences: {
    permission: ['admin.ui']
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Hint for adding an article to an existing ticket.'),
  name:        'ui_ticket_add_article_hint',
  area:        'UI::TicketZoomArticle',
  description: __('Highlights if the note a user is writing is public or private'),
  options:     {},
  state:       {
    # 'note-internal' => 'You are writing an |internal note|, only people of your organization will see it.',
    # 'note-public' => 'You are writing a |public note|.',
    # 'phone-internal' => 'You are writing an |internal phone note|, only people of your organization will see it.',
    # 'phone-public' => 'You are writing a |public phone note|.',
    # ....
  },
  preferences: {
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Ticket Overview Query Polling'),
  name:        'ui_ticket_overview_query_polling',
  area:        'UI::TicketOverview::QueryPolling',
  description: __('System-wide configuration of the query polling mechanism for ticket overviews.'),
  options:     {},
  state:       {
    enabled:    true,
    page_size:  30,
    background: {
      calculation_count: 3,
      interval_sec:      10,
      cache_ttl_sec:     10,
    },
    foreground: {
      interval_sec:  5,
      cache_ttl_sec: 5,
    },
    counts:     {
      interval_sec:  60,
      cache_ttl_sec: 60,
    },
  },
  preferences: {
    permission: ['admin.ui'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('S/MIME integration'),
  name:        'smime_integration',
  area:        'Integration::Switch',
  description: __('Defines if S/MIME encryption is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'smime_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('S/MIME config'),
  name:        'smime_config',
  area:        'Integration::SMIME',
  description: __('Defines the S/MIME config.'),
  options:     {},
  state:       {},
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    true,
)

Setting.create_if_not_exists(
  title:       __('PGP integration'),
  name:        'pgp_integration',
  area:        'Integration::Switch',
  description: __('Defines if PGP encryption is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'pgp_integration',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    prio:           1,
    authentication: true,
    permission:     ['admin.integration'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('PGP config'),
  name:        'pgp_config',
  area:        'Integration::PGP',
  description: __('Defines the PGP config.'),
  options:     {},
  state:       {},
  preferences: {
    prio:       2,
    permission: ['admin.integration'],
  },
  frontend:    true,
)

Setting.create_if_not_exists(
  title:       __('PGP Recipient Alias Configuration'),
  name:        'pgp_recipient_alias_configuration',
  area:        'Core::Integration::PGP',
  description: __('Defines if the PGP recipient alias configuration is enabled or not.'),
  options:     {},
  state:       false,
  preferences: { online_service_disable: true },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Authentication via %s'),
  name:        'auth_sso',
  area:        'Security::ThirdPartyAuthentication',
  description: __('Enables button for user authentication via %s. The button will redirect to /auth/sso on user interaction.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'auth_sso',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:       'SettingsAreaSwitch',
    sub:              {},
    title_i18n:       [__('SSO')],
    description_i18n: [__('SSO')],
    permission:       ['admin.security'],
  },
  state:       false,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Show calendar weeks in the picker of date/datetime fields'),
  name:        'datepicker_show_calendar_weeks',
  area:        'System::UI',
  description: __('Defines if calendar weeks are shown in the picker of date/datetime fields to easily select the correct date.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'datepicker_show_calendar_weeks',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    render:     true,
    prio:       4,
    permission: ['admin.system'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Security Keys'),
  name:        'two_factor_authentication_method_security_keys',
  area:        'Security::TwoFactorAuthentication',
  description: __('Defines if the two-factor authentication method security keys is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'two_factor_authentication_method_security_keys',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:   'SettingsAreaSwitch',
    sub:          {},
    permission:   ['admin.security'],
    prio:         1000,
    display_name: __('Security Keys'),
    help:         __('Complete the sign-in with your security key.'),
    icon:         'security-key',
  },
  state:       false,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Authenticator App'),
  name:        'two_factor_authentication_method_authenticator_app',
  area:        'Security::TwoFactorAuthentication',
  description: __('Defines if the two-factor authentication method authenticator app is enabled or not.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'two_factor_authentication_method_authenticator_app',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller:   'SettingsAreaSwitch',
    sub:          {},
    permission:   ['admin.security'],
    prio:         2000,
    display_name: __('Authenticator App'),
    help:         __('Get the security code from the authenticator app on your device.'),
    icon:         'mobile-code',
  },
  state:       false,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Enable Recovery Codes'),
  name:        'two_factor_authentication_recovery_codes',
  area:        'Security::TwoFactorAuthentication',
  description: __('Defines if recovery codes can be used by users in the event they lose access to other two-factor authentication methods.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'two_factor_authentication_recovery_codes',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    prio:       5000,
    permission: ['admin.security'],
  },
  state:       true,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Enforce the setup of the two-factor authentication'),
  name:        'two_factor_authentication_enforce_role_ids',
  area:        'Security::TwoFactorAuthentication',
  description: __('Requires the setup of the two-factor authentication for certain user roles.'),
  options:     {
    form: [
      {
        display:   __('Enforced for user roles'),
        null:      true,
        name:      'two_factor_authentication_enforce_role_ids',
        tag:       'column_select',
        relation:  'Role',
        translate: true,
      },
    ],
  },
  preferences: {
    permission: ['admin.security'],
    prio:       6000,
  },
  state:       [2],
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Ticket Organization Reassignment'),
  name:        'ticket_organization_reassignment',
  area:        'Ticket::Base',
  description: __('Defines if the change of the primary organization of a user will update the 100 most recent tickets for this user as well.'),
  options:     {
    form: [
      {
        display:   '',
        null:      false,
        name:      'ticket_organization_reassignment',
        tag:       'boolean',
        options:   {
          true  => __('Update the most recent tickets.'),
          false => __('Do not update any tickets.'),
        },
        translate: true,
      },
    ],
  },
  state:       true,
  preferences: {
    prio:       4000,
    permission: ['admin.ticket'],
  },
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Checklists'),
  name:        'checklist',
  area:        'Web::Base',
  description: __('Enable checklists.'),
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'checklist',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission:     ['admin.checklist'],
  },
  state:       true,
  frontend:    true
)

Setting.create_if_not_exists(
  title:       __('Auto Shutdown'),
  name:        'auto_shutdown',
  area:        'Core::WebApp',
  description: __('Enable or disable self-shutdown of Zammad processes after significant configuration changes. This should only be used if the controlling process manager like systemd or docker supports an automatic restart policy.'),
  options:     {},
  state:       !Rails.env.test?,
  preferences: { online_service_disable: true },
  frontend:    false
)

Setting.create_if_not_exists(
  title:       __('UI Desktop Beta Switch'),
  name:        'ui_desktop_beta_switch',
  area:        'UI::Desktop',
  description: __('Allow users to switch automatically to the new desktop UI.'),
  state:       false,
  frontend:    true,
)
