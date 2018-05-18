Setting.create_if_not_exists(
  title: 'Application secret',
  name: 'application_secret',
  area: 'Core',
  description: 'Defines the random application secret.',
  options: {},
  state: SecureRandom.hex(128),
  preferences: {
    permission: ['admin'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'System Init Done',
  name: 'system_init_done',
  area: 'Core',
  description: 'Defines if application is in init mode.',
  options: {},
  state: false,
  preferences: { online_service_disable: true },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'App Version',
  name: 'app_version',
  area: 'Core::WebApp',
  description: 'Only used internally to propagate current web app version to clients.',
  options: {},
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Maintenance Mode',
  name: 'maintenance_mode',
  area: 'Core::WebApp',
  description: 'Enable or disable the maintenance mode of Zammad. If enabled, all non-administrators get logged out and only administrators can start a new session.',
  options: {},
  state: false,
  preferences: {
    permission: ['admin.maintenance'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Maintenance Login',
  name: 'maintenance_login',
  area: 'Core::WebApp',
  description: 'Put a message on the login page. To change it, click on the text area below and change it inline.',
  options: {},
  state: false,
  preferences: {
    permission: ['admin.maintenance'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Maintenance Login',
  name: 'maintenance_login_message',
  area: 'Core::WebApp',
  description: 'Message for login page.',
  options: {},
  state: 'Something about to share. Click here to change.',
  preferences: {
    permission: ['admin.maintenance'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Developer System',
  name: 'developer_mode',
  area: 'Core::Develop',
  description: 'Defines if application is in developer mode (useful for developer, all users have the same password, password reset will work without email delivery).',
  options: {},
  state: false,
  preferences: { online_service_disable: true },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Online Service',
  name: 'system_online_service',
  area: 'Core',
  description: 'Defines if application is used as online service.',
  options: {},
  state: false,
  preferences: { online_service_disable: true },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Product Name',
  name: 'product_name',
  area: 'System::Branding',
  description: 'Defines the name of the application, shown in the web interface, tabs and title bar of the web browser.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'product_name',
        tag: 'input',
      },
    ],
  },
  preferences: {
    render: true,
    prio: 1,
    placeholder: true,
    permission: ['admin.branding'],
  },
  state: 'Zammad Helpdesk',
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Logo',
  name: 'product_logo',
  area: 'System::Branding',
  description: 'Defines the logo of the application, shown in the web interface.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'product_logo',
        tag: 'input',
      },
    ],
  },
  preferences: {
    prio: 3,
    controller: 'SettingsAreaLogo',
    permission: ['admin.branding'],
  },
  state: 'logo.svg',
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Organization',
  name: 'organization',
  area: 'System::Branding',
  description: 'Will be shown in the app and is included in email footers.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'organization',
        tag: 'input',
      },
    ],
  },
  state: '',
  preferences: {
    prio: 2,
    placeholder: true,
    permission: ['admin.branding'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Locale',
  name: 'locale_default',
  area: 'System::Branding',
  description: 'Defines the system default language.',
  options: {
    form: [
      {
        name: 'locale_default',
      }
    ],
  },
  state: 'en-us',
  preferences: {
    prio: 8,
    controller: 'SettingsAreaItemDefaultLocale',
    permission: ['admin.system'],
  },
  frontend: true
)
Setting.create_or_update(
  title: 'Pretty Date',
  name: 'pretty_date_format',
  area: 'System::Branding',
  description: 'Defines pretty date format.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'pretty_date_format',
        tag: 'select',
        options: {
          'relative': 'relative - e. g. "2 hours ago" or "2 days and 15 minutes ago"',
          'absolute': 'absolute - e. g. "Monday 09:30" or "Tuesday 23. Feb 14:20"',
        },
      },
    ],
  },
  preferences: {
    render: true,
    prio: 10,
    permission: ['admin.branding'],
  },
  state: 'relative',
  frontend: true
)
options = {}
(10..99).each do |item|
  options[item] = item
end
system_id = rand(10..99)
Setting.create_if_not_exists(
  title: 'SystemID',
  name: 'system_id',
  area: 'System::Base',
  description: 'Defines the system identifier. Every ticket number contains this ID. This ensures that only tickets which belong to your system will be processed as follow-ups (useful when communicating between two instances of Zammad).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'system_id',
        tag: 'select',
        options: options,
      },
    ],
  },
  state: system_id,
  preferences: {
    online_service_disable: true,
    placeholder: true,
    authentication: true,
    permission: ['admin.system'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Fully Qualified Domain Name',
  name: 'fqdn',
  area: 'System::Base',
  description: 'Defines the fully qualified domain name of the system. This setting is used as a variable, #{setting.fqdn} which is found in all forms of messaging used by the application, to build links to the tickets within your system.', # rubocop:disable Lint/InterpolationCheck
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'fqdn',
        tag: 'input',
      },
    ],
  },
  state: 'zammad.example.com',
  preferences: {
    online_service_disable: true,
    placeholder: true,
    permission: ['admin.system'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Websocket port',
  name: 'websocket_port',
  area: 'System::WebSocket',
  description: 'Defines the port of the websocket server.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'websocket_port',
        tag: 'input',
      },
    ],
  },
  state: '6042',
  preferences: { online_service_disable: true },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'HTTP type',
  name: 'http_type',
  area: 'System::Base',
  description: 'Define the http protocol of your instance.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'http_type',
        tag: 'select',
        options: {
          'https' => 'https',
          'http'  => 'http',
        },
      },
    ],
  },
  state: 'http',
  preferences: {
    online_service_disable: true,
    placeholder: true,
    permission: ['admin.system'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Storage Mechanism',
  name: 'storage_provider',
  area: 'System::Storage',
  description: '"Database" stores all attachments in the database (not recommended for storing large amounts of data). "Filesystem" stores the data in the filesystem. You can switch between the modules even on a system that is already in production without any loss of data.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'storage_provider',
        tag: 'select',
        tranlate: true,
        options: {
          'DB' => 'Database',
          'File' => 'Filesystem',
        },
      },
    ],
  },
  state: 'DB',
  preferences: {
    controller: 'SettingsAreaStorageProvider',
    online_service_disable: true,
    permission: ['admin.system'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Image Service',
  name: 'image_backend',
  area: 'System::Services',
  description: 'Defines the backend for user and organization image lookups.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'image_backend',
        tag: 'select',
        options: {
          '' => '-',
          'Service::Image::Zammad' => 'Zammad Image Service',
        },
      },
    ],
  },
  state: 'Service::Image::Zammad',
  preferences: {
    prio: 1,
    permission: ['admin.system'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Geo IP Service',
  name: 'geo_ip_backend',
  area: 'System::Services',
  description: 'Defines the backend for geo IP lookups. Shows also location of an IP address if an IP address is shown.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'geo_ip_backend',
        tag: 'select',
        options: {
          '' => '-',
          'Service::GeoIp::Zammad' => 'Zammad GeoIP Service',
        },
      },
    ],
  },
  state: 'Service::GeoIp::Zammad',
  preferences: {
    prio: 2,
    permission: ['admin.system'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Geo Location Service',
  name: 'geo_location_backend',
  area: 'System::Services',
  description: 'Defines the backend for geo location lookups to store geo locations for addresses.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'geo_location_backend',
        tag: 'select',
        options: {
          '' => '-',
          'Service::GeoLocation::Gmaps' => 'Google Maps',
        },
      },
    ],
  },
  state: 'Service::GeoLocation::Gmaps',
  preferences: {
    prio: 3,
    permission: ['admin.system'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Geo Calendar Service',
  name: 'geo_calendar_backend',
  area: 'System::Services',
  description: 'Defines the backend for geo calendar lookups. Used for initial calendar succession.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'geo_calendar_backend',
        tag: 'select',
        options: {
          '' => '-',
          'Service::GeoCalendar::Zammad' => 'Zammad GeoCalendar Service',
        },
      },
    ],
  },
  state: 'Service::GeoCalendar::Zammad',
  preferences: {
    prio: 2,
    permission: ['admin.system'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Proxy Settings',
  name: 'proxy',
  area: 'System::Network',
  description: 'Address of the proxy server for http and https resources.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'proxy',
        tag: 'input',
        placeholder: 'proxy.example.com:3128',
      },
    ],
  },
  state: '',
  preferences: {
    online_service_disable: true,
    controller: 'SettingsAreaProxy',
    prio: 1,
    permission: ['admin.system'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Proxy User',
  name: 'proxy_username',
  area: 'System::Network',
  description: 'Username for proxy connection.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'proxy_username',
        tag: 'input',
      },
    ],
  },
  state: '',
  preferences: {
    disabled: true,
    online_service_disable: true,
    prio: 2,
    permission: ['admin.system'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Proxy Password',
  name: 'proxy_password',
  area: 'System::Network',
  description: 'Password for proxy connection.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'proxy_password',
        tag: 'input',
      },
    ],
  },
  state: '',
  preferences: {
    disabled: true,
    online_service_disable: true,
    prio: 3,
    permission: ['admin.system'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'No Proxy',
  name: 'proxy_no',
  area: 'System::Network',
  description: 'No proxy for the following hosts.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'proxy_no',
        tag: 'input',
      },
    ],
  },
  state: 'localhost,127.0.0.0,::1',
  preferences: {
    disabled: true,
    online_service_disable: true,
    prio: 4,
    permission: ['admin.system'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Send client stats',
  name: 'ui_send_client_stats',
  area: 'System::UI',
  description: 'Send client stats/error message to central server to improve the usability.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_send_client_stats',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    permission: ['admin.system'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Client storage',
  name: 'ui_client_storage',
  area: 'System::UI',
  description: 'Use client storage to cache data to enhance performance of application.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_client_storage',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 2,
    permission: ['admin.system'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'User Organization Selector - email',
  name: 'ui_user_organization_selector_with_email',
  area: 'UI::UserOrganizatiomSelector',
  description: 'Display of the e-mail in the result of the user/organization widget.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_user_organization_selector_with_email',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 100,
    permission: ['admin.ui'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Note - default visibility',
  name: 'ui_ticket_zoom_article_note_new_internal',
  area: 'UI::TicketZoom',
  description: 'Default visibility for new note.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_ticket_zoom_article_note_new_internal',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'internal',
          false => 'public',
        },
      },
    ],
  },
  state: true,
  preferences: {
    prio: 100,
    permission: ['admin.ui'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Email - subject field',
  name: 'ui_ticket_zoom_article_email_subject',
  area: 'UI::TicketZoom',
  description: 'Use subject field for emails. If disabled, the ticket title will be used as subject.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_ticket_zoom_article_email_subject',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 200,
    permission: ['admin.ui'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Email - full quote',
  name: 'ui_ticket_zoom_article_email_full_quote',
  area: 'UI::TicketZoom',
  description: 'Enable if you want to quote the full email in your answer. The quoted email will be put at the end of your answer. If you just want to quote a certain phrase, just mark the text and press reply (this feature is always available).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_ticket_zoom_article_email_full_quote',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 220,
    permission: ['admin.ui'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Twitter - tweet initials',
  name: 'ui_ticket_zoom_article_twitter_initials',
  area: 'UI::TicketZoom',
  description: 'Add sender initials to end of a tweet.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_ticket_zoom_article_twitter_initials',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    prio: 300,
    permission: ['admin.ui'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Sidebar Attachments',
  name: 'ui_ticket_zoom_attachments_preview',
  area: 'UI::TicketZoom::Preview',
  description: 'Enables preview of attachments.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_ticket_zoom_attachments_preview',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 400,
    permission: ['admin.ui'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Sidebar Attachments',
  name: 'ui_ticket_zoom_sidebar_article_attachments',
  area: 'UI::TicketZoom::Preview',
  description: 'Enables a sidebar to show an overview of all attachments.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_ticket_zoom_sidebar_article_attachments',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 500,
    permission: ['admin.ui'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Set notes for ticket create types.',
  name: 'ui_ticket_create_notes',
  area: 'UI::TicketCreate',
  description: 'Set notes for ticket create types by selecting type.',
  options: {},
  state: {
    #'email-out' => 'Attention: When creating a ticket an e-mail is sent.',
  },
  preferences: {
    permission: ['admin.ui'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Default type for a new ticket',
  name: 'ui_ticket_create_default_type',
  area: 'UI::TicketCreate',
  description: 'Select default ticket type',
  options: {
    form: [
      {
        display: '',
        null: false,
        multiple: false,
        name: 'ui_ticket_create_default_type',
        tag: 'select',
        options: {
          'phone-in' => '1. Phone inbound',
          'phone-out' => '2. Phone outbound',
          'email-out' => '3. Email outbound',
        },
      },
    ],
  },
  state: 'phone-in',
  preferences: {
    permission: ['admin.ui']
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Available types for a new ticket',
  name: 'ui_ticket_create_available_types',
  area: 'UI::TicketCreate',
  description: 'Set available ticket types',
  options: {
    form: [
      {
        display: '',
        null: false,
        multiple: true,
        name: 'ui_ticket_create_available_types',
        tag: 'select',
        options: {
          'phone-in' => '1. Phone inbound',
          'phone-out' => '2. Phone outbound',
          'email-out' => '3. Email outbound',
        },
      },
    ],
  },
  state: %w[phone-in phone-out email-out],
  preferences: {
    permission: ['admin.ui']
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Open ticket indicator',
  name: 'ui_sidebar_open_ticket_indicator_colored',
  area: 'UI::Sidebar',
  description: 'Color representation of the open ticket indicator in the sidebar.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_sidebar_open_ticket_indicator_colored',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    permission: ['admin.ui'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Open ticket indicator',
  name: 'ui_table_group_by_show_count',
  area: 'UI::Base',
  description: 'Total display of the number of objects in a grouping.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ui_table_group_by_show_count',
        tag: 'boolean',
        translate: true,
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    permission: ['admin.ui'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'New User Accounts',
  name: 'user_create_account',
  area: 'Security::Base',
  description: 'Enables users to create their own account via web interface.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'user_create_account',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    permission: ['admin.security'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Lost Password',
  name: 'user_lost_password',
  area: 'Security::Base',
  description: 'Activates lost password feature for users.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'user_lost_password',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    permission: ['admin.security'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'User email for muliple users',
  name: 'user_email_multiple_use',
  area: 'Model::User',
  description: 'Allow to use email address for muliple users.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'user_email_multiple_use',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    permission: ['admin'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_ldap',
  area: 'Security::Authentication',
  description: 'Enables user authentication via %s.',
  preferences: {
    title_i18n: ['LDAP'],
    description_i18n: ['LDAP'],
    permission: ['admin.security'],
  },
  state: {
    adapter: 'Auth::Ldap',
    host: 'localhost',
    port: 389,
    bind_dn: 'cn=Manager,dc=example,dc=org',
    bind_pw: 'example',
    uid: 'mail',
    base: 'dc=example,dc=org',
    always_filter: '',
    always_roles: %w[Admin Agent],
    always_groups: ['Users'],
    sync_params: {
      firstname: 'sn',
      lastname: 'givenName',
      email: 'mail',
      login: 'mail',
    },
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Automatic account link on initial logon',
  name: 'auth_third_party_auto_link_at_inital_login',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables the automatic linking of an existing account on initial login via a third party application. If this is disabled, an existing user must first log into Zammad and then link his "Third Party" account to his Zammad account via Profile -> Linked Accounts.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_third_party_auto_link_at_inital_login',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    permission: ['admin.security'],
    prio: 10,
  },
  state: false,
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_twitter',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_twitter',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_twitter_credentials'],
    title_i18n: ['Twitter'],
    description_i18n: ['Twitter', 'Twitter Developer Site', 'https://dev.twitter.com/apps'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Twitter App Credentials',
  name: 'auth_twitter_credentials',
  area: 'Security::ThirdPartyAuthentication::Twitter',
  description: 'App credentials for Twitter.',
  options: {
    form: [
      {
        display: 'Twitter Key',
        null: true,
        name: 'key',
        tag: 'input',
      },
      {
        display: 'Twitter Secret',
        null: true,
        name: 'secret',
        tag: 'input',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_facebook',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_facebook',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_facebook_credentials'],
    title_i18n: ['Facebook'],
    description_i18n: ['Facebook', 'Facebook Developer Site', 'https://developers.facebook.com/apps/'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Facebook App Credentials',
  name: 'auth_facebook_credentials',
  area: 'Security::ThirdPartyAuthentication::Facebook',
  description: 'App credentials for Facebook.',
  options: {
    form: [
      {
        display: 'App ID',
        null: true,
        name: 'app_id',
        tag: 'input',
      },
      {
        display: 'App Secret',
        null: true,
        name: 'app_secret',
        tag: 'input',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_google_oauth2',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_google_oauth2',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_google_oauth2_credentials'],
    title_i18n: ['Google'],
    description_i18n: ['Google', 'Google API Console Site', 'https://console.developers.google.com/apis/credentials'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Google App Credentials',
  name: 'auth_google_oauth2_credentials',
  area: 'Security::ThirdPartyAuthentication::Google',
  description: 'Enables user authentication via Google.',
  options: {
    form: [
      {
        display: 'Client ID',
        null: true,
        name: 'client_id',
        tag: 'input',
      },
      {
        display: 'Client Secret',
        null: true,
        name: 'client_secret',
        tag: 'input',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_linkedin',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_linkedin',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_linkedin_credentials'],
    title_i18n: ['LinkedIn'],
    description_i18n: ['LinkedIn', 'Linkedin Developer Site', 'https://www.linkedin.com/developer/apps'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'LinkedIn App Credentials',
  name: 'auth_linkedin_credentials',
  area: 'Security::ThirdPartyAuthentication::Linkedin',
  description: 'Enables user authentication via LinkedIn.',
  options: {
    form: [
      {
        display: 'App ID',
        null: true,
        name: 'app_id',
        tag: 'input',
      },
      {
        display: 'App Secret',
        null: true,
        name: 'app_secret',
        tag: 'input',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_github',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_github',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_github_credentials'],
    title_i18n: ['Github'],
    description_i18n: ['Github', 'Github OAuth Applications', 'https://github.com/settings/applications'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Github App Credentials',
  name: 'auth_github_credentials',
  area: 'Security::ThirdPartyAuthentication::Github',
  description: 'Enables user authentication via Github.',
  options: {
    form: [
      {
        display: 'App ID',
        null: true,
        name: 'app_id',
        tag: 'input',
      },
      {
        display: 'App Secret',
        null: true,
        name: 'app_secret',
        tag: 'input',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_gitlab',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_gitlab',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_gitlab_credentials'],
    title_i18n: ['Gitlab'],
    description_i18n: ['Gitlab', 'Gitlab Applications', 'https://your-gitlab-host/admin/applications'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Gitlab App Credentials',
  name: 'auth_gitlab_credentials',
  area: 'Security::ThirdPartyAuthentication::Gitlab',
  description: 'Enables user authentication via Gitlab.',
  options: {
    form: [
      {
        display: 'App ID',
        null: true,
        name: 'app_id',
        tag: 'input',
      },
      {
        display: 'App Secret',
        null: true,
        name: 'app_secret',
        tag: 'input',
      },
      {
        display: 'Site',
        null: true,
        name: 'site',
        tag: 'input',
        placeholder: 'https://gitlab.YOURDOMAIN.com',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_microsoft_office365',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_microsoft_office365',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_microsoft_office365_credentials'],
    title_i18n: ['Office 365'],
    description_i18n: ['Office 365', 'Microsoft Application Registration Portal', 'https://apps.dev.microsoft.com'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Office 365 App Credentials',
  name: 'auth_microsoft_office365_credentials',
  area: 'Security::ThirdPartyAuthentication::Office365',
  description: 'Enables user authentication via Office 365.',
  options: {
    form: [
      {
        display: 'App ID',
        null: true,
        name: 'app_id',
        tag: 'input',
      },
      {
        display: 'App Secret',
        null: true,
        name: 'app_secret',
        tag: 'input',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_oauth2',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via generic OAuth2. Register your app first.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_oauth2',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_oauth2_credentials'],
    title_i18n: ['Generic OAuth2'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Generic OAuth2 App Credentials',
  name: 'auth_oauth2_credentials',
  area: 'Security::ThirdPartyAuthentication::GenericOAuth',
  description: 'Enables user authentication via generic OAuth2.',
  options: {
    form: [
      {
        display: 'Name',
        null: true,
        name: 'name',
        tag: 'input',
        placeholder: 'Some Provider Name',
      },
      {
        display: 'App ID',
        null: true,
        name: 'app_id',
        tag: 'input',
      },
      {
        display: 'App Secret',
        null: true,
        name: 'app_secret',
        tag: 'input',
      },
      {
        display: 'Site',
        null: true,
        name: 'site',
        tag: 'input',
        placeholder: 'https://oauth.YOURDOMAIN.com',
      },
      {
        display: 'authorize_url',
        null: true,
        name: 'authorize_url',
        tag: 'input',
        placeholder: '/oauth/authorize',
      },
      {
        display: 'token_url',
        null: true,
        name: 'token_url',
        tag: 'input',
        placeholder: '/oauth/token',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via %s',
  name: 'auth_weibo',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via %s. Register your app first at [%s](%s).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'auth_weibo',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    controller: 'SettingsAreaSwitch',
    sub: ['auth_weibo_credentials'],
    title_i18n: ['Weibo'],
    description_i18n: ['Sina Weibo', 'Sina Weibo Open Protal', 'http://open.weibo.com'],
    permission: ['admin.security'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Weibo App Credentials',
  name: 'auth_weibo_credentials',
  area: 'Security::ThirdPartyAuthentication::Weibo',
  description: 'Enables user authentication via Weibo.',
  options: {
    form: [
      {
        display: 'App ID',
        null: true,
        name: 'client_id',
        tag: 'input',
      },
      {
        display: 'App Secret',
        null: true,
        name: 'client_secret',
        tag: 'input',
      },
    ],
  },
  state: {},
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Minimum length',
  name: 'password_min_size',
  area: 'Security::Password',
  description: 'Password needs to have at least a minimal number of characters.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'password_min_size',
        tag: 'select',
        options: {
          4 => ' 4',
          5 => ' 5',
          6 => ' 6',
          7 => ' 7',
          8 => ' 8',
          9 => ' 9',
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
  state: 6,
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: '2 lower and 2 upper characters',
  name: 'password_min_2_lower_2_upper_characters',
  area: 'Security::Password',
  description: 'Password needs to contain 2 lower and 2 upper characters.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'password_min_2_lower_2_upper_characters',
        tag: 'select',
        options: {
          1 => 'yes',
          0 => 'no',
        },
      },
    ],
  },
  state: 0,
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Digit required',
  name: 'password_need_digit',
  area: 'Security::Password',
  description: 'Password needs to contain at least one digit.',
  options: {
    form: [
      {
        display: 'Needed',
        null: true,
        name: 'password_need_digit',
        tag: 'select',
        options: {
          1 => 'yes',
          0 => 'no',
        },
      },
    ],
  },
  state: 1,
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Maximum failed logins',
  name: 'password_max_login_failed',
  area: 'Security::Password',
  description: 'Number of failed logins after account will be deactivated.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'password_max_login_failed',
        tag: 'select',
        options: {
          4 => ' 4',
          5 => ' 5',
          6 => ' 6',
          7 => ' 7',
          8 => ' 8',
          9 => ' 9',
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
  state: 10,
  preferences: {
    permission: ['admin.security'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Ticket Hook',
  name: 'ticket_hook',
  area: 'Ticket::Base',
  description: 'The identifier for a ticket, e. g. Ticket#, Call#, MyTicket#. The default is Ticket#.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'ticket_hook',
        tag: 'input',
      },
    ],
  },
  preferences: {
    render: true,
    placeholder: true,
    authentication: true,
    permission: ['admin.ticket'],
  },
  state: 'Ticket#',
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Ticket Hook Divider',
  name: 'ticket_hook_divider',
  area: 'Ticket::Base::Shadow',
  description: 'The divider between TicketHook and ticket number. E. g. \': \'.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_hook_divider',
        tag: 'input',
      },
    ],
  },
  state: '',
  preferences: {
    permission: ['admin.ticket'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Hook Position',
  name: 'ticket_hook_position',
  area: 'Ticket::Base',
  description: "The format of the subject.
* **Right** means **Some Subject [Ticket#12345]**
* **Left** means **[Ticket#12345] Some Subject**
* **None** means **Some Subject** (without ticket number). In the last case you should enable *postmaster_follow_up_search_in* to recognize follow-ups based on email headers and/or body.",
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_hook_position',
        tag: 'select',
        translate: true,
        options: {
          'left'  => 'left',
          'right' => 'right',
          'none'  => 'none',
        },
      },
    ],
  },
  state: 'right',
  preferences: {
    controller: 'SettingsAreaTicketHookPosition',
    permission: ['admin.ticket'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Last Contact Behaviour',
  name: 'ticket_last_contact_behaviour',
  area: 'Ticket::Base',
  description: 'Sets the last customer contact based on the last contact of a customer or on the last contact of a customer to whom an agent has not yet responded.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_last_contact_behaviour',
        tag: 'select',
        translate: true,
        options: {
          'based_on_customer_reaction' => 'Last customer contact (without consideration an agent has replied to it)',
          'check_if_agent_already_replied' => 'Last customer contact (with consideration an agent has replied to it)',
        },
      },
    ],
  },
  state: 'check_if_agent_already_replied',
  preferences: {
    permission: ['admin.ticket'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Number Format',
  name: 'ticket_number',
  area: 'Ticket::Number',
  description: "Selects the ticket number generator module.
* **Increment** increments the ticket number, the SystemID and the counter are used with SystemID.Counter format (e.g. 1010138, 1010139).
* With **Date** the ticket numbers will be generated by the current date, the SystemID and the counter. The format looks like Year.Month.Day.SystemID.counter (e.g. 201206231010138, 201206231010139).",
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_number',
        tag: 'select',
        translate: true,
        options: {
          'Ticket::Number::Increment' => 'Increment (SystemID.Counter)',
          'Ticket::Number::Date'      => 'Date (Year.Month.Day.SystemID.Counter)',
        },
      },
    ],
  },
  state: 'Ticket::Number::Increment',
  preferences: {
    settings_included: %w[ticket_number_increment ticket_number_date],
    controller: 'SettingsAreaTicketNumber',
    permission: ['admin.ticket'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Number Increment',
  name: 'ticket_number_increment',
  area: 'Ticket::Number',
  description: '-',
  options: {
    form: [
      {
        display: 'Checksum',
        null: true,
        name: 'checksum',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
      {
        display: 'Min. size of number',
        null: true,
        name: 'min_size',
        tag: 'select',
        options: {
          1 => ' 1',
          2 => ' 2',
          3 => ' 3',
          4 => ' 4',
          5 => ' 5',
          6 => ' 6',
          7 => ' 7',
          8 => ' 8',
          9 => ' 9',
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
  state: {
    checksum: false,
    min_size: 5,
  },
  preferences: {
    permission: ['admin.ticket'],
    hidden: true,
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Number Increment Date',
  name: 'ticket_number_date',
  area: 'Ticket::Number',
  description: '-',
  options: {
    form: [
      {
        display: 'Checksum',
        null: true,
        name: 'checksum',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: {
    checksum: false
  },
  preferences: {
    permission: ['admin.ticket'],
    hidden: true,
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Auto Assigment',
  name: 'ticket_auto_assignment',
  area: 'Web::Base',
  description: 'Enable ticket auto assignment.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_auto_assignment',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission: ['admin.ticket_auto_assignment'],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Time Accounting Selector',
  name: 'ticket_auto_assignment_selector',
  area: 'Web::Base',
  description: 'Enable auto assignment for following matching tickets.',
  options: {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission: ['admin.ticket_auto_assignment'],
  },
  state: { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } },
  frontend: true
)
Setting.create_or_update(
  title: 'Time Accounting Selector',
  name: 'ticket_auto_assignment_user_ids_ignore',
  area: 'Web::Base',
  description: 'Define an exception of "automatic assignment" for certain users (e.g. executives).',
  options: {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission: ['admin.ticket_auto_assignment'],
  },
  state: [],
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Ticket Number ignore system_id',
  name: 'ticket_number_ignore_system_id',
  area: 'Ticket::Core',
  description: '-',
  options: {
    form: [
      {
        display: 'Ignore system_id',
        null: true,
        name: 'ticket_number_ignore_system_id',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: {
    ticket_number_ignore_system_id: false
  },
  preferences: {
    permission: ['admin.ticket'],
    hidden: true,
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Recursive Ticket Triggers',
  name: 'ticket_trigger_recursive',
  area: 'Ticket::Core',
  description: 'Activate the recursive processing of ticket triggers.',
  options: {
    form: [
      {
        display: 'Recursive Ticket Triggers',
        null: true,
        name: 'ticket_trigger_recursive',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    permission: ['admin.ticket'],
    hidden: true,
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Recursive Ticket Triggers Loop Max.',
  name: 'ticket_trigger_recursive_max_loop',
  area: 'Ticket::Core',
  description: 'Maximum number of recursively executed triggers.',
  options: {
    form: [
      {
        display: 'Recursive Ticket Triggers',
        null: true,
        name: 'ticket_trigger_recursive_max_loop',
        tag: 'select',
        options: {
          1 => ' 1',
          2 => ' 2',
          3 => ' 3',
          4 => ' 4',
          5 => ' 5',
          6 => ' 6',
          7 => ' 7',
          8 => ' 8',
          9 => ' 9',
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
  state: 10,
  preferences: {
    permission: ['admin.ticket'],
    hidden: true,
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Enable Ticket creation',
  name: 'customer_ticket_create',
  area: 'CustomerWeb::Base',
  description: 'Defines if a customer can create tickets via the web interface.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'customer_ticket_create',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    authentication: true,
    permission: ['admin.channel_web'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Group selection for Ticket creation',
  name: 'customer_ticket_create_group_ids',
  area: 'CustomerWeb::Base',
  description: 'Defines groups for which a customer can create tickets via web interface. "-" means all groups are available.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'group_ids',
        tag: 'select',
        multiple: true,
        nulloption: true,
        relation: 'Group',
      },
    ],
  },
  state: '',
  preferences: {
    authentication: true,
    permission: ['admin.channel_web'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Enable Ticket creation',
  name: 'form_ticket_create',
  area: 'Form::Base',
  description: 'Defines if tickets can be created via web form.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'form_ticket_create',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend: false,
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
  title: 'Group selection for Ticket creation',
  name: 'form_ticket_create_group_id',
  area: 'Form::Base',
  description: 'Defines if group of created tickets via web form.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'form_ticket_create_group_id',
        tag: 'select',
        relation: 'Group',
      },
    ],
  },
  state: group_id,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend: false,
)

Setting.create_if_not_exists(
  title: 'Limit tickets by ip per hour',
  name: 'form_ticket_create_by_ip_per_hour',
  area: 'Form::Base',
  description: 'Defines limit of tickets by ip per hour via web form.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'form_ticket_create_by_ip_per_hour',
        tag: 'input',
      },
    ],
  },
  state: 20,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'Limit tickets by ip per day',
  name: 'form_ticket_create_by_ip_per_day',
  area: 'Form::Base',
  description: 'Defines limit of tickets by ip per day via web form.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'form_ticket_create_by_ip_per_day',
        tag: 'input',
      },
    ],
  },
  state: 240,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'Limit tickets per day',
  name: 'form_ticket_create_per_day',
  area: 'Form::Base',
  description: 'Defines limit of tickets per day via web form.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'form_ticket_create_per_day',
        tag: 'input',
      },
    ],
  },
  state: 5000,
  preferences: {
    permission: ['admin.channel_formular'],
  },
  frontend: false,
)

Setting.create_if_not_exists(
  title: 'Ticket Subject Size',
  name: 'ticket_subject_size',
  area: 'Email::Base',
  description: 'Max. length of the subject in an email reply.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'ticket_subject_size',
        tag: 'input',
      },
    ],
  },
  state: '110',
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Subject Reply',
  name: 'ticket_subject_re',
  area: 'Email::Base',
  description: 'The text at the beginning of the subject in an email reply, e. g. RE, AW, or AS.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_subject_re',
        tag: 'input',
      },
    ],
  },
  state: 'RE',
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Ticket Subject Forward',
  name: 'ticket_subject_fwd',
  area: 'Email::Base',
  description: 'The text at the beginning of the subject in an email forward, e. g. FWD.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_subject_fwd',
        tag: 'input',
      },
    ],
  },
  state: 'FWD',
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Sender Format',
  name: 'ticket_define_email_from',
  area: 'Email::Base',
  description: 'Defines how the From field of emails (sent from answers and email tickets) should look like.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_define_email_from',
        tag: 'select',
        options: {
          SystemAddressName: 'System Address Display Name',
          AgentNameSystemAddressName: 'Agent Name + FromSeparator + System Address Display Name',
        },
      },
    ],
  },
  state: 'AgentNameSystemAddressName',
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Sender Format Separator',
  name: 'ticket_define_email_from_separator',
  area: 'Email::Base',
  description: 'Defines the separator between the agent\'s real name and the given group email address.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'ticket_define_email_from_separator',
        tag: 'input',
      },
    ],
  },
  state: 'via',
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Maximum Email Size',
  name: 'postmaster_max_size',
  area: 'Email::Base',
  description: 'Maximum size in MB of emails.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'postmaster_max_size',
        tag: 'select',
        options: {
          1 => '  1',
          2 => '  2',
          3 => '  3',
          4 => '  4',
          5 => '  5',
          6 => '  6',
          7 => '  7',
          8 => '  8',
          9 => '  9',
          10 => ' 10',
          15 => ' 15',
          20 => ' 20',
          25 => ' 25',
          30 => ' 30',
          35 => ' 35',
          40 => ' 40',
          45 => ' 45',
          50 => ' 50',
          60 => ' 60',
          70 => ' 70',
          80 => ' 80',
          90 => ' 90',
          100 => '100',
          125 => '125',
          150 => '150',
        },
      },
    ],
  },
  state: 10,
  preferences: {
    online_service_disable: true,
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Additional follow-up detection',
  name: 'postmaster_follow_up_search_in',
  area: 'Email::Base',
  description: 'By default the follow-up check is done via the subject of an email. With this setting you can add more fields for which the follow-up check will be executed.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'postmaster_follow_up_search_in',
        tag: 'checkbox',
        options: {
          'references' => 'References - Search for follow up also in In-Reply-To or References headers.',
          'body'       => 'Body - Search for follow up also in mail body.',
          'attachment' => 'Attachment - Search for follow up also in attachments.',
        },
      },
    ],
  },
  state: [],
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Sender based on Reply-To header',
  name: 'postmaster_sender_based_on_reply_to',
  area: 'Email::Base',
  description: 'Set/overwrite sender/from of email based on reply-to header. Useful to set correct customer if email is received from a third party system on behalf of a customer.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'postmaster_sender_based_on_reply_to',
        tag: 'select',
        options: {
          ''                                     => '-',
          'as_sender_of_email'                   => 'Take reply-to header as sender/from of email.',
          'as_sender_of_email_use_from_realname' => 'Take reply-to header as sender/from of email and use realname of origin from.',
        },
      },
    ],
  },
  state: [],
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Customer selection based on sender and receiver list',
  name: 'postmaster_sender_is_agent_search_for_customer',
  area: 'Email::Base',
  description: 'If the sender is an agent, set the first user in the recipient list as a customer.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'postmaster_sender_is_agent_search_for_customer',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Notification Sender',
  name: 'notification_sender',
  area: 'Email::Base',
  description: 'Defines the sender of email notifications.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'notification_sender',
        tag: 'input',
      },
    ],
  },
  state: 'Notification Master <noreply@#{config.fqdn}>', # rubocop:disable Lint/InterpolationCheck
  preferences: {
    online_service_disable: true,
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Block Notifications',
  name: 'send_no_auto_response_reg_exp',
  area: 'Email::Base',
  description: 'If this regex matches, no notification will be sent by the sender.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'send_no_auto_response_reg_exp',
        tag: 'input',
      },
    ],
  },
  state: '(mailer-daemon|postmaster|abuse|root|noreply|noreply.+?|no-reply|no-reply.+?)@.+?',
  preferences: {
    online_service_disable: true,
    permission: ['admin.channel_email'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'API Token Access',
  name: 'api_token_access',
  area: 'API::Base',
  description: 'Enable REST API using tokens (not username/email address and password). Each user needs to create its own access tokens in user profile.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'api_token_access',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    permission: ['admin.api'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'API Password Access',
  name: 'api_password_access',
  area: 'API::Base',
  description: 'Enable REST API access using the username/email address and password for the authentication user.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'api_password_access',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    permission: ['admin.api'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Monitoring Token',
  name: 'monitoring_token',
  area: 'HealthCheck::Base',
  description: 'Token for monitoring.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'monitoring_token',
        tag: 'input',
      },
    ],
  },
  state: ENV['MONITORING_TOKEN'] || SecureRandom.urlsafe_base64(40),
  preferences: {
    permission: ['admin.monitoring'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Enable Chat',
  name: 'chat',
  area: 'Chat::Base',
  description: 'Enable/disable online chat.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'chat',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    trigger: ['menu:render', 'chat:rerender'],
    permission: ['admin.channel_chat'],
  },
  state: false,
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Agent idle timeout',
  name: 'chat_agent_idle_timeout',
  area: 'Chat::Extended',
  description: 'Idle timeout in seconds until agent is set offline automatically.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'chat_agent_idle_timeout',
        tag: 'input',
      },
    ],
  },
  state: '120',
  preferences: {
    permission: ['admin.channel_chat'],
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Defines searchable models.',
  name: 'models_searchable',
  area: 'Models::Base',
  description: 'Defines the searchable models.',
  options: {},
  state: [],
  preferences: {
    authentication: true,
  },
  frontend: true,
)

Setting.create_if_not_exists(
  title: 'Default Screen',
  name: 'default_controller',
  area: 'Core',
  description: 'Defines the default screen.',
  options: {},
  state: '#dashboard',
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Elasticsearch Endpoint URL',
  name: 'es_url',
  area: 'SearchIndex::Elasticsearch',
  description: 'Defines endpoint of Elasticsearch.',
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elasticsearch Endpoint User',
  name: 'es_user',
  area: 'SearchIndex::Elasticsearch',
  description: 'Defines HTTP basic auth user of Elasticsearch.',
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elasticsearch Endpoint Password',
  name: 'es_password',
  area: 'SearchIndex::Elasticsearch',
  description: 'Defines HTTP basic auth password of Elasticsearch.',
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elasticsearch Endpoint Index',
  name: 'es_index',
  area: 'SearchIndex::Elasticsearch',
  description: 'Defines Elasticsearch index name.',
  state: 'zammad',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elasticsearch Attachment Extensions',
  name: 'es_attachment_ignore',
  area: 'SearchIndex::Elasticsearch',
  description: 'Defines attachment extensions which will be ignored by Elasticsearch.',
  state: [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe', '.box', '.mbox' ],
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elasticsearch Attachment Size',
  name: 'es_attachment_max_size_in_mb',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define max. attachment size for Elasticsearch.',
  state: 50,
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elasticsearch Pipeline Name',
  name: 'es_pipeline',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define pipeline name for Elasticsearch.',
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Import Mode',
  name: 'import_mode',
  area: 'Import::Base',
  description: 'Puts Zammad into import mode (disables some triggers).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'import_mode',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Import Backend',
  name: 'import_backend',
  area: 'Import::Base::Internal',
  description: 'Set backend which is being used for import.',
  options: {},
  state: '',
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Ignore Escalation/SLA Information',
  name: 'import_ignore_sla',
  area: 'Import::Base',
  description: 'Ignore escalation/SLA information for import.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'import_ignore_sla',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Import Endpoint',
  name: 'import_otrs_endpoint',
  area: 'Import::OTRS',
  description: 'Defines OTRS endpoint to import users, tickets, states and articles.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'import_otrs_endpoint',
        tag: 'input',
      },
    ],
  },
  state: 'http://otrs_host/otrs',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Import Key',
  name: 'import_otrs_endpoint_key',
  area: 'Import::OTRS',
  description: 'Defines OTRS endpoint authentication key.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'import_otrs_endpoint_key',
        tag: 'input',
      },
    ],
  },
  state: '',
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Import User for HTTP basic authentication',
  name: 'import_otrs_user',
  area: 'Import::OTRS',
  description: 'Defines HTTP basic authentication user (only if OTRS is protected via HTTP basic auth).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'import_otrs_user',
        tag: 'input',
      },
    ],
  },
  state: '',
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Import Password for http basic authentication',
  name: 'import_otrs_password',
  area: 'Import::OTRS',
  description: 'Defines http basic authentication password (only if OTRS is protected via http basic auth).',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'import_otrs_password',
        tag: 'input',
      },
    ],
  },
  state: '',
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Import Endpoint',
  name: 'import_zendesk_endpoint',
  area: 'Import::Zendesk',
  description: 'Defines Zendesk endpoint to import users, ticket, states and articles.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'import_zendesk_endpoint',
        tag: 'input',
      },
    ],
  },
  state: 'https://yours.zendesk.com/api/v2',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Import Key for requesting the Zendesk API',
  name: 'import_zendesk_endpoint_key',
  area: 'Import::Zendesk',
  description: 'Defines Zendesk endpoint authentication key.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'import_zendesk_endpoint_key',
        tag: 'input',
      },
    ],
  },
  state: '',
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Import User for requesting the Zendesk API',
  name: 'import_zendesk_endpoint_username',
  area: 'Import::Zendesk',
  description: 'Defines Zendesk endpoint authentication user.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'import_zendesk_endpoint_username',
        tag: 'input',
      },
    ],
  },
  state: '',
  frontend: false
)
Setting.create_if_not_exists(
  title:       'Import Backends',
  name:        'import_backends',
  area:        'Import',
  description: 'A list of active import backends that get scheduled automatically.',
  options:     {},
  state:       ['Import::Ldap', 'Import::Exchange'],
  preferences: {
    permission: ['admin'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title:       'Sequencer log level',
  name:        'sequencer_log_level',
  area:        'Core',
  description: 'Defines the log levels for various logging actions of the Sequencer.',
  options:     {},
  state:       {
    sequence: {
      start_finish: :debug,
      unit:         :debug,
      result:       :debug,
    },
    state: {
      optional: :debug,
      set:      :debug,
      get:      :debug,
      attribute_initialization: {
        start_finish: :debug,
        attributes:   :debug,
      },
      parameter_initialization: {
        parameters:   :debug,
        start_finish: :debug,
        unused:       :debug,
      },
      expectations_initialization: :debug,
      cleanup: {
        start_finish: :debug,
        remove:       :debug,
      }
    }
  },
  frontend: false,
)

Setting.create_if_not_exists(
  title: 'Time Accounting',
  name: 'time_accounting',
  area: 'Web::Base',
  description: 'Enable time accounting.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'time_accounting',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission: ['admin.time_accounting'],
  },
  state: false,
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Time Accounting Selector',
  name: 'time_accounting_selector',
  area: 'Web::Base',
  description: 'Enable time accounting for these tickets.',
  options: {
    form: [
      {},
    ],
  },
  preferences: {
    authentication: true,
    permission: ['admin.time_accounting'],
  },
  state: {},
  frontend: true
)

Setting.create_if_not_exists(
  title: 'New Tags',
  name: 'tag_new',
  area: 'Web::Base',
  description: 'Allow users to create new tags.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'tag_new',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  preferences: {
    authentication: true,
    permission: ['admin.tag'],
  },
  state: true,
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Default calendar tickets subscriptions',
  name: 'defaults_calendar_subscriptions_tickets',
  area: 'Defaults::CalendarSubscriptions',
  description: 'Defines the default calendar tickets subscription settings.',
  options: {},
  state: {
    escalation: {
      own: true,
      not_assigned: false,
    },
    new_open: {
      own: true,
      not_assigned: false,
    },
    pending: {
      own: true,
      not_assigned: false,
    }
  },
  preferences: {
    authentication: true,
  },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Defines translator identifier.',
  name: 'translator_key',
  area: 'i18n::translator_key',
  description: 'Defines the translator identifier for contributions.',
  options: {},
  state: '',
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0010_postmaster_filter_trusted',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to remove X-Zammad headers from not trusted sources.',
  options: {},
  state: 'Channel::Filter::Trusted',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0011_postmaster_sender_based_on_reply_to',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to set the sender/from of emails based on reply-to header.',
  options: {},
  state: 'Channel::Filter::ReplyToBasedSender',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0012_postmaster_filter_sender_is_system_address',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to check if email has been created by Zammad itself and will set the article sender.',
  options: {},
  state: 'Channel::Filter::SenderIsSystemAddress',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0014_postmaster_filter_own_notification_loop_detection',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to check if email is a own created notification email, then ignore it to prevent email loops.',
  options: {},
  state: 'Channel::Filter::OwnNotificationLoopDetection',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0015_postmaster_filter_identify_sender',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to identify sender user.',
  options: {},
  state: 'Channel::Filter::IdentifySender',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0020_postmaster_filter_auto_response_check',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to identify auto responses to prevent auto replies from Zammad.',
  options: {},
  state: 'Channel::Filter::AutoResponseCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0030_postmaster_filter_out_of_office_check',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to identify out-of-office emails for follow-up detection and keeping current ticket state.',
  options: {},
  state: 'Channel::Filter::OutOfOfficeCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0100_postmaster_filter_follow_up_check',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to identify follow-ups (based on admin settings).',
  options: {},
  state: 'Channel::Filter::FollowUpCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0110_postmaster_filter_follow_up_merged',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to identify follow-up ticket for merged tickets.',
  options: {},
  state: 'Channel::Filter::FollowUpMerged',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0200_postmaster_filter_follow_up_possible_check',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to check if follow ups get created (based on admin settings).',
  options: {},
  state: 'Channel::Filter::FollowUpPossibleCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0900_postmaster_filter_bounce_follow_up_check',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to identify postmaster bounced - to handle it as follow-up of the original ticket.',
  options: {},
  state: 'Channel::Filter::BounceFollowUpCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '0950_postmaster_filter_bounce_delivery_permanent_failed',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to identify postmaster bounced - disable sending notification on permanent deleivery failed.',
  options: {},
  state: 'Channel::Filter::BounceDeliveryPermanentFailed',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '1000_postmaster_filter_database_check',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter for filters managed via admin interface.',
  options: {},
  state: 'Channel::Filter::Database',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '5000_postmaster_filter_icinga',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to manage Icinga (http://www.icinga.org) emails.',
  options: {},
  state: 'Channel::Filter::Icinga',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '5100_postmaster_filter_nagios',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to manage Nagios (http://www.nagios.org) emails.',
  options: {},
  state: 'Channel::Filter::Nagios',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines postmaster filter.',
  name: '5300_postmaster_filter_monit',
  area: 'Postmaster::PreFilter',
  description: 'Defines postmaster filter to manage Monit (https://mmonit.com/monit/) emails.',
  options: {},
  state: 'Channel::Filter::Monit',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Icinga integration',
  name: 'icinga_integration',
  area: 'Integration::Switch',
  description: 'Defines if Icinga (http://www.icinga.org) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'icinga_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Sender',
  name: 'icinga_sender',
  area: 'Integration::Icinga',
  description: 'Defines the sender email address of Icinga emails.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'icinga_sender',
        tag: 'input',
        placeholder: 'icinga@monitoring.example.com',
      },
    ],
  },
  state: 'icinga@monitoring.example.com',
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'Auto close',
  name: 'icinga_auto_close',
  area: 'Integration::Icinga',
  description: 'Defines if tickets should be closed if service is recovered.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'icinga_auto_close',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    prio: 3,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Auto close state',
  name: 'icinga_auto_close_state_id',
  area: 'Integration::Icinga',
  description: 'Defines the state of auto closed tickets.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'icinga_auto_close_state_id',
        tag: 'select',
        relation: 'TicketState',
      },
    ],
  },
  state: 4,
  preferences: {
    prio: 4,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Nagios integration',
  name: 'nagios_integration',
  area: 'Integration::Switch',
  description: 'Defines if Nagios (http://www.nagios.org) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'nagios_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Sender',
  name: 'nagios_sender',
  area: 'Integration::Nagios',
  description: 'Defines the sender email address of Nagios emails.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'nagios_sender',
        tag: 'input',
        placeholder: 'nagios@monitoring.example.com',
      },
    ],
  },
  state: 'nagios@monitoring.example.com',
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'Auto close',
  name: 'nagios_auto_close',
  area: 'Integration::Nagios',
  description: 'Defines if tickets should be closed if service is recovered.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'nagios_auto_close',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    prio: 3,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Auto close state',
  name: 'nagios_auto_close_state_id',
  area: 'Integration::Nagios',
  description: 'Defines the state of auto closed tickets.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'nagios_auto_close_state_id',
        tag: 'select',
        relation: 'TicketState',
      },
    ],
  },
  state: 4,
  preferences: {
    prio: 4,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Check_MK integration',
  name: 'check_mk_integration',
  area: 'Integration::Switch',
  description: 'Defines if Check_MK (http://mathias-kettner.com/check_mk.html) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'check_mk_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Group',
  name: 'check_mk_group_id',
  area: 'Integration::CheckMK',
  description: 'Defines the group of created tickets.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'check_mk_group_id',
        tag: 'select',
        relation: 'Group',
      },
    ],
  },
  state: 1,
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Auto close',
  name: 'check_mk_auto_close',
  area: 'Integration::CheckMK',
  description: 'Defines if tickets should be closed if service is recovered.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'check_mk_auto_close',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  preferences: {
    prio: 3,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Auto close state',
  name: 'check_mk_auto_close_state_id',
  area: 'Integration::CheckMK',
  description: 'Defines the state of auto closed tickets.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'check_mk_auto_close_state_id',
        tag: 'select',
        relation: 'TicketState',
      },
    ],
  },
  state: 4,
  preferences: {
    prio: 4,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Check_MK tolen',
  name: 'check_mk_token',
  area: 'Core',
  description: 'Defines the Check_MK token for allowing updates.',
  options: {},
  state: ENV['CHECK_MK_TOKEN'] || SecureRandom.hex(16),
  preferences: {
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Monit integration',
  name: 'monit_integration',
  area: 'Integration::Switch',
  description: 'Defines if Monit (https://mmonit.com/monit/) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'monit_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Sender',
  name: 'monit_sender',
  area: 'Integration::Monit',
  description: 'Defines the sender email address of the service emails.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'monit_sender',
        tag: 'input',
        placeholder: 'monit@monitoring.example.com',
      },
    ],
  },
  state: 'monit@monitoring.example.com',
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'Auto close',
  name: 'monit_auto_close',
  area: 'Integration::Monit',
  description: 'Defines if tickets should be closed if service is recovered.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'monit_auto_close',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
        translate: true,
      },
    ],
  },
  state: true,
  preferences: {
    prio: 3,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Auto close state',
  name: 'monit_auto_close_state_id',
  area: 'Integration::Monit',
  description: 'Defines the state of auto closed tickets.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'monit_auto_close_state_id',
        tag: 'select',
        relation: 'TicketState',
        translate: true,
      },
    ],
  },
  state: 4,
  preferences: {
    prio: 4,
    permission: ['admin.integration'],
  },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'LDAP integration',
  name: 'ldap_integration',
  area: 'Integration::Switch',
  description: 'Defines if LDAP is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ldap_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    authentication: true,
    permission: ['admin.integration'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Exchange config',
  name: 'exchange_config',
  area: 'Integration::Exchange',
  description: 'Defines the Exchange config.',
  options: {},
  state: {},
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'Exchange integration',
  name: 'exchange_integration',
  area: 'Integration::Switch',
  description: 'Defines if Exchange is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'exchange_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    authentication: true,
    permission: ['admin.integration'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'LDAP config',
  name: 'ldap_config',
  area: 'Integration::LDAP',
  description: 'Defines the LDAP config.',
  options: {},
  state: {},
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'i-doit integration',
  name: 'idoit_integration',
  area: 'Integration::Switch',
  description: 'Defines if i-doit (http://www.i-doit) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'idoit_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    authentication: true,
    permission: ['admin.integration'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'i-doit config',
  name: 'idoit_config',
  area: 'Integration::Idoit',
  description: 'Defines the i-doit config.',
  options: {},
  state: {},
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'Defines sync transaction backend.',
  name: '0100_trigger',
  area: 'Transaction::Backend::Sync',
  description: 'Defines the transaction backend to execute triggers.',
  options: {},
  state: 'Transaction::Trigger',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines transaction backend.',
  name: '0100_notification',
  area: 'Transaction::Backend::Async',
  description: 'Defines the transaction backend to send agent notifications.',
  options: {},
  state: 'Transaction::Notification',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines transaction backend.',
  name: '1000_signature_detection',
  area: 'Transaction::Backend::Async',
  description: 'Defines the transaction backend to detect customer signatures in emails.',
  options: {},
  state: 'Transaction::SignatureDetection',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines transaction backend.',
  name: '6000_slack_webhook',
  area: 'Transaction::Backend::Async',
  description: 'Defines the transaction backend which posts messages to Slack (http://www.slack.com).',
  options: {},
  state: 'Transaction::Slack',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Slack integration',
  name: 'slack_integration',
  area: 'Integration::Switch',
  description: 'Defines if Slack (http://www.slack.org) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'slack_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Slack config',
  name: 'slack_config',
  area: 'Integration::Slack',
  description: 'Defines the slack config.',
  options: {},
  state: {
    items: []
  },
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'sipgate.io integration',
  name: 'sipgate_integration',
  area: 'Integration::Switch',
  description: 'Defines if sipgate.io (http://www.sipgate.io) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'sipgate_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    trigger: ['menu:render', 'cti:reload'],
    authentication: true,
    permission: ['admin.integration'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'sipgate.io config',
  name: 'sipgate_config',
  area: 'Integration::Sipgate',
  description: 'Defines the sipgate.io config.',
  options: {},
  state: { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'cti integration',
  name: 'cti_integration',
  area: 'Integration::Switch',
  description: 'Defines if generic CTI is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'cti_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    trigger: ['menu:render', 'cti:reload'],
    authentication: true,
    permission: ['admin.integration'],
  },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'cti config',
  name: 'cti_config',
  area: 'Integration::Cti',
  description: 'Defines the cti config.',
  options: {},
  state: { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
  frontend: false,
)
Setting.create_if_not_exists(
  title: 'CTI Token',
  name: 'cti_token',
  area: 'Integration::Cti',
  description: 'Token for cti.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'cti_token',
        tag: 'input',
      },
    ],
  },
  state: ENV['CTI_TOKEN'] || SecureRandom.urlsafe_base64(20),
  preferences: {
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Clearbit integration',
  name: 'clearbit_integration',
  area: 'Integration::Switch',
  description: 'Defines if Clearbit (http://www.clearbit.com) is enabled or not.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'clearbit_integration',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: false,
  preferences: {
    prio: 1,
    permission: ['admin.integration'],
  },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Clearbit config',
  name: 'clearbit_config',
  area: 'Integration::Clearbit',
  description: 'Defines the Clearbit config.',
  options: {},
  state: {},
  frontend: false,
  preferences: {
    prio: 2,
    permission: ['admin.integration'],
  },
)
Setting.create_if_not_exists(
  title: 'Defines transaction backend.',
  name: '9000_clearbit_enrichment',
  area: 'Transaction::Backend::Async',
  description: 'Defines the transaction backend which will enrich customer and organization information from Clearbit (http://www.clearbit.com).',
  options: {},
  state: 'Transaction::ClearbitEnrichment',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines transaction backend.',
  name: '9100_cti_caller_id_detection',
  area: 'Transaction::Backend::Async',
  description: 'Defines the transaction backend which detects caller IDs in objects and store them for CTI lookups.',
  options: {},
  state: 'Transaction::CtiCallerIdDetection',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines transaction backend.',
  name: '9200_karma',
  area: 'Transaction::Backend::Async',
  description: 'Defines the transaction backend which creates the karma score.',
  options: {},
  state: 'Transaction::Karma',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Defines karma levels.',
  name: 'karma_levels',
  area: 'Core::Karma',
  description: 'Defines the karma levels.',
  options: {},
  state: [
    {
      name: 'Beginner',
      start: 0,
      end: 499,
    },
    {
      name: 'Newbie',
      start: 500,
      end: 1999,
    },
    {
      name: 'Intermediate',
      start: 2000,
      end: 4999,
    },
    {
      name: 'Professional',
      start: 5000,
      end: 6999,
    },
    {
      name: 'Expert',
      start: 7000,
      end: 8999,
    },
    {
      name: 'Master',
      start: 9000,
      end: 18_999,
    },
    {
      name: 'Evangelist',
      start: 19_000,
      end: 45_999,
    },
    {
      name: 'Hero',
      start: 50_000,
      end: nil,
    },
  ],
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Set limit of agents',
  name: 'system_agent_limit',
  area: 'Core::Online',
  description: 'Defines the limit of the agents.',
  options: {},
  state: false,
  preferences: { online_service_disable: true },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'HTML Email CSS Font',
  name: 'html_email_css_font',
  area: 'Core',
  description: 'Defines the CSS font information for HTML Emails.',
  options: {},
  state: "font-family:'Helvetica Neue', Helvetica, Arial, Geneva, sans-serif; font-size: 12px;",
  preferences: {
    permission: ['admin'],
  },
  frontend: false
)
