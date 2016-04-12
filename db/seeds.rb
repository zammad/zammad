# encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
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
  description: 'Only used for internal, to propagate current web app version to clients.',
  options: {},
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
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
  preferences: { render: true, session_check: true, prio: 1 },
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
  preferences: { prio: 3 },
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
  preferences: { prio: 2 },
  frontend: true
)
options = {}
(10..99).each {|item|
  options[item] = item
}
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
  preferences: { online_service_disable: true },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Fully Qualified Domain Name',
  name: 'fqdn',
  area: 'System::Base',
  description: 'Defines the fully qualified domain name of the system. This setting is used as a variable, #{setting.fqdn} which is found in all forms of messaging used by the application, to build links to the tickets within your system.',
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
  preferences: { online_service_disable: true },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'websocket port',
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
  title: 'http type',
  name: 'http_type',
  area: 'System::Base',
  description: 'Defines the type of protocol, used by the web server, to serve the application. If https protocol will be used instead of plain http, it must be specified in here. Since this has no affect on the web server\'s settings or behavior, it will not change the method of access to the application and, if it is wrong, it will not prevent you from logging into the application. This setting is used as a variable, #{setting.http_type} which is found in all forms of messaging used by the application, to build links to the tickets within your system.',
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
  preferences: { online_service_disable: true },
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Storage Mechanism',
  name: 'storage',
  area: 'System::Storage',
  description: '"Database" stores all attachments in the database (not recommended for storing large amounts of data). "Filesystem" stores the data on the filesystem. You can switch between the modules even on a system that is already in production without any loss of data.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'storage',
        tag: 'select',
        options: {
          'DB' => 'Database',
          'FS' => 'Filesystem',
        },
      },
    ],
  },
  state: 'DB',
  preferences: { online_service_disable: true },
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
  preferences: { prio: 1 },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Geo IP Service',
  name: 'geo_ip_backend',
  area: 'System::Services',
  description: 'Defines the backend for geo IP lookups. Show also location of an IP address if an IP address is shown.',
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
  preferences: { prio: 2 },
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
  preferences: { prio: 3 },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Geo Calendar Service',
  name: 'geo_calendar_backend',
  area: 'System::Services',
  description: 'Defines the backend for geo calendar lookups. Used for inital calendar succession.',
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
  preferences: { prio: 2 },
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
  state: true,
  preferences: { prio: 1 },
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Client storage',
  name: 'ui_client_storage',
  area: 'System::UI',
  description: 'Use client storage to cache data to perform speed of application.',
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
  preferences: { prio: 2 },
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
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Authentication via LDAP',
  name: 'auth_ldap',
  area: 'Security::Authentication',
  description: 'Enables user authentication via LDAP.',
  state: {
    adapter: 'Auth::Ldap',
    host: 'localhost',
    port: 389,
    bind_dn: 'cn=Manager,dc=example,dc=org',
    bind_pw: 'example',
    uid: 'mail',
    base: 'dc=example,dc=org',
    always_filter: '',
    always_roles: %w(Admin Agent),
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
  title: 'Authentication via Twitter',
  name: 'auth_twitter',
  area: 'Security::ThirdPartyAuthentication',
  description: "@T('Enables user authentication via twitter. Register your app first at [Twitter Developer Site](https://dev.twitter.com/apps)')",
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
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Twitter App Credentials',
  name: 'auth_twitter_credentials',
  area: 'Security::ThirdPartyAuthentication',
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
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Authentication via Facebook',
  name: 'auth_facebook',
  area: 'Security::ThirdPartyAuthentication',
  description: "@T('Enables user authentication via Facebook. Register your app first at [Facebook Developer Site](https://developers.facebook.com/apps/)')",
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
  state: false,
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Facebook App Credentials',
  name: 'auth_facebook_credentials',
  area: 'Security::ThirdPartyAuthentication',
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
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via Google',
  name: 'auth_google_oauth2',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via Google.',
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
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Google App Credentials',
  name: 'auth_google_oauth2_credentials',
  area: 'Security::ThirdPartyAuthentication',
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
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Authentication via LinkedIn',
  name: 'auth_linkedin',
  area: 'Security::ThirdPartyAuthentication',
  description: 'Enables user authentication via LinkedIn.',
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
  state: false,
  frontend: true
)
Setting.create_if_not_exists(
  title: 'LinkedIn App Credentials',
  name: 'auth_linkedin_credentials',
  area: 'Security::ThirdPartyAuthentication',
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
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Minimal size',
  name: 'password_min_size',
  area: 'Security::Password',
  description: 'Password need to have at least minimal size of characters.',
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
  frontend: true
)
Setting.create_if_not_exists(
  title: '2 lower and 2 upper characters',
  name: 'password_min_2_lower_2_upper_characters',
  area: 'Security::Password',
  description: 'Password need to contain 2 lower and 2 upper characters.',
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
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Digit required',
  name: 'password_need_digit',
  area: 'Security::Password',
  description: 'Password need to have at least one digit.',
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
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Maximal failed logins',
  name: 'password_max_login_failed',
  area: 'Security::Password',
  description: 'Maximal failed logins after account is inactive.',
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
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Ticket Hook',
  name: 'ticket_hook',
  area: 'Ticket::Base',
  description: 'The identifier for a ticket, e.g. Ticket#, Call#, MyTicket#. The default is Ticket#.',
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
  preferences: { render: true },
  state: 'Ticket#',
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Ticket Hook Divider',
  name: 'ticket_hook_divider',
  area: 'Ticket::Base::Shadow',
  description: 'The divider between TicketHook and ticket number. E.g \': \'.',
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
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Hook Position',
  name: 'ticket_hook_position',
  area: 'Ticket::Base',
  description: "@T('The format of the subject.')
* @T('**Right** means **Some Subject [Ticket#12345]**')
* @T('**Left** means **[Ticket#12345] Some Subject**')
* @T('**None** means **Some Subject** (without ticket number). In the last case you should enable *postmaster_follow_up_search_in* to recognize followups based on email headers and/or body.')",
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_hook_position',
        tag: 'select',
        options: {
          'left'  => 'left',
          'right' => 'right',
          'none'  => 'none',
        },
      },
    ],
  },
  state: 'right',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Subject Size',
  name: 'ticket_subject_size',
  area: 'Ticket::Base',
  description: 'Max size of the subjects in an email reply.',
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
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Subject Reply',
  name: 'ticket_subject_re',
  area: 'Ticket::Base',
  description: 'The text at the beginning of the subject in an email reply, e.g. RE, AW, or AS.',
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
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Ticket Number Format',
  name: 'ticket_number',
  area: 'Ticket::Number',
  description: "@T('Selects the ticket number generator module.')
* @T('**Increment** increments the ticket number, the SystemID and the counter are used with SystemID.Counter format (e.g. 1010138, 1010139).')
* @T('With **Date** the ticket numbers will be generated by the current date, the SystemID and the counter. The format looks like Year.Month.Day.SystemID.counter (e.g. 201206231010138, 201206231010139).')

@T('With param 'Checksum => true' the counter will be appended as checksum to the string. The format looks like SystemID.Counter.CheckSum (e. g. 10101384, 10101392) or Year.Month.Day.SystemID.Counter.CheckSum (e.g. 2012070110101520, 2012070110101535).')",
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'ticket_number',
        tag: 'select',
        options: {
          'Ticket::Number::Increment' => 'Increment (SystemID.Counter)',
          'Ticket::Number::Date'      => 'Date (Year.Month.Day.SystemID.Counter)',
        },
      },
    ],
  },
  state: 'Ticket::Number::Increment',
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
    checksum: false,
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
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Group selection for Ticket creation',
  name: 'customer_ticket_create_group_ids',
  area: 'CustomerWeb::Base',
  description: 'Defines groups where customer can create tickets via web interface. "-" means all groups are available.',
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
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Enable Ticket View/Update',
  name: 'customer_ticket_view',
  area: 'CustomerWeb::Base',
  description: 'Defines if a customer view and update his own tickets.',
  options: {
    form: [
      {
        display: '',
        null: true,
        name: 'customer_ticket_view',
        tag: 'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state: true,
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Enable Ticket creation',
  name: 'form_ticket_create',
  area: 'Form::Base',
  description: 'Defines if ticket can get created via web form.',
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
  frontend: false,
)

Setting.create_if_not_exists(
  title: 'Sender Format',
  name: 'ticket_define_email_from',
  area: 'Email::Base',
  description: 'Defines how the From field from the emails (sent from answers and email tickets) should look like.',
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
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Sender Format Seperator',
  name: 'ticket_define_email_from_seperator',
  area: 'Email::Base',
  description: 'Defines the separator between the agents real name and the given group email address.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'ticket_define_email_from_seperator',
        tag: 'input',
      },
    ],
  },
  state: 'via',
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Max. Email Size',
  name: 'postmaster_max_size',
  area: 'Email::Base',
  description: 'Maximal size in MB of emails.',
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
  preferences: { online_service_disable: true },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Additional follow up detection',
  name: 'postmaster_follow_up_search_in',
  area: 'Email::Base',
  description: 'In default the follow up check is done via the subject of an email. With this setting you can add more fields where the follow up ckeck is executed.',
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
  state: 'Notification Master <noreply@#{config.fqdn}>',
  preferences: { online_service_disable: true },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Block Notifications',
  name: 'send_no_auto_response_reg_exp',
  area: 'Email::Base',
  description: 'If this regex matches, no notification will be send by the sender.',
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
  state: '(MAILER-DAEMON|postmaster|abuse)@.+?\..+?',
  preferences: { online_service_disable: true },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Enable Chat',
  name: 'chat',
  area: 'Chat::Base',
  description: 'Enable/Disable online chat.',
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
  preferences: { render: true },
  state: false,
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Agent idle timeout',
  name: 'chat_agent_idle_timeout',
  area: 'Chat::Extended',
  description: 'Idle timeout in seconds till agent is set offline automatically.',
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
  preferences: {},
  state: '120',
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Define searchable models.',
  name: 'models_searchable',
  area: 'Models::Base',
  description: 'Define the models which can be searched for.',
  options: {},
  state: [],
  frontend: false,
)

Setting.create_if_not_exists(
  title: 'Default Screen',
  name: 'default_controller',
  area: 'Core',
  description: 'Defines the default controller.',
  options: {},
  state: '#dashboard',
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Elasticsearch Endpoint URL',
  name: 'es_url',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define endpoint of Elastic Search.',
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elasticsearch Endpoint User',
  name: 'es_user',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define http basic auth user of Elasticsearch.',
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elastic Search Endpoint Password',
  name: 'es_password',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define http basic auth password of Elasticsearch.',
  state: '',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elastic Search Endpoint Index',
  name: 'es_index',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define Elasticsearch index name.',
  state: 'zammad',
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elastic Search Attachment Extentions',
  name: 'es_attachment_ignore',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define attachment extentions which are ignored for Elasticsearch.',
  state: [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe', '.box', '.mbox' ],
  preferences: { online_service_disable: true },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Elastic Search Attachment Size',
  name: 'es_attachment_max_size_in_mb',
  area: 'SearchIndex::Elasticsearch',
  description: 'Define max. attachment size for Elasticsearch.',
  state: 50,
  preferences: { online_service_disable: true },
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Import Mode',
  name: 'import_mode',
  area: 'Import::Base',
  description: 'Set system in import mode (disable some triggers).',
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
  description: 'Set backend which is used for import.',
  options: {},
  state: '',
  frontend: true
)
Setting.create_if_not_exists(
  title: 'Ignore Escalation/SLA Information',
  name: 'import_ignore_sla',
  area: 'Import::Base',
  description: 'Ignore Escalation/SLA Information form import system.',
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
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Import Endpoint',
  name: 'import_otrs_endpoint',
  area: 'Import::OTRS',
  description: 'Defines OTRS endpoint to import users, ticket, states and articles.',
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
  description: 'Defines OTRS endpoint auth key.',
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
  title: 'Import User for http basic authentication',
  name: 'import_otrs_user',
  area: 'Import::OTRS',
  description: 'Defines http basic authentication user (only if OTRS is protected via http basic auth).',
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
  description: 'Defines Zendesk endpoint auth key.',
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
  description: 'Defines Zendesk endpoint auth key.',
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
  title: 'Default calendar Tickets subscriptions',
  name: 'defaults_calendar_subscriptions_tickets',
  area: 'Defaults::CalendarSubscriptions',
  description: 'Defines the default calendar Tickets subscription settings.',
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
  frontend: true
)

Setting.create_if_not_exists(
  title: 'Define translator identifier.',
  name: 'translator_key',
  area: 'i18n::translator_key',
  description: 'Defines the translator identifier for contributions.',
  options: {},
  state: '',
  frontend: false
)

Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '0010_postmaster_filter_trusted',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to remove X-Zammad-Headers from not trusted sources.',
  options: {},
  state: 'Channel::Filter::Trusted',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '0015_postmaster_filter_identify_sender',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to identify sender user.',
  options: {},
  state: 'Channel::Filter::IdentifySender',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '0020_postmaster_filter_auto_response_check',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to identify auto responses to prevent auto replies from Zammad.',
  options: {},
  state: 'Channel::Filter::AutoResponseCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '0030_postmaster_filter_out_of_office_check',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to identify out of office emails for follow up detection and keeping current ticket state.',
  options: {},
  state: 'Channel::Filter::OutOfOfficeCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '0100_postmaster_filter_follow_up_check',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to identify follow ups (based on admin settings).',
  options: {},
  state: 'Channel::Filter::FollowUpCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '0900_postmaster_filter_bounce_check',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter to identify postmaster bounced - to handle it as follow up of origin ticket.',
  options: {},
  state: 'Channel::Filter::BounceCheck',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '1000_postmaster_filter_database_check',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter for filters managed via admin interface.',
  options: {},
  state: 'Channel::Filter::Database',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '5000_postmaster_filter_icinga',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter for manage Icinga (http://www.icinga.org) emails.',
  options: {},
  state: 'Channel::Filter::Icinga',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Define postmaster filter.',
  name: '5100_postmaster_filter_nagios',
  area: 'Postmaster::PreFilter',
  description: 'Define postmaster filter for manage Nagios (http://www.nagios.org) emails.',
  options: {},
  state: 'Channel::Filter::Nagios',
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Icinga integration',
  name: 'icinga_integration',
  area: 'Integration::Icinga',
  description: 'Define if Icinga (http://www.icinga.org) is enabled or not.',
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
  preferences: { prio: 1 },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Sender',
  name: 'icinga_sender',
  area: 'Integration::Icinga',
  description: 'Define the sender email address of Icinga emails.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'icinga_sender',
        tag: 'input',
      },
    ],
  },
  state: 'icinga@monitoring.example.com',
  frontend: false,
  preferences: { prio: 2 },
)
Setting.create_if_not_exists(
  title: 'Auto close',
  name: 'icinga_auto_close',
  area: 'Integration::Icinga',
  description: 'Define if tickets should be closed if service is recovered.',
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
  preferences: { prio: 3 },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Auto close state',
  name: 'icinga_auto_close_state_id',
  area: 'Integration::Icinga',
  description: 'Define the ticket state of auto closed tickets.',
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
  preferences: { prio: 4 },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Nagios integration',
  name: 'nagios_integration',
  area: 'Integration::Nagios',
  description: 'Define if Nagios (http://www.nagios.org) is enabled or not.',
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
  preferences: { prio: 1 },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Sender',
  name: 'nagios_sender',
  area: 'Integration::Nagios',
  description: 'Define the sender email address of Nagios emails.',
  options: {
    form: [
      {
        display: '',
        null: false,
        name: 'nagios_sender',
        tag: 'input',
      },
    ],
  },
  state: 'nagios@monitoring.example.com',
  frontend: false,
  preferences: { prio: 2 },
)
Setting.create_if_not_exists(
  title: 'Auto close',
  name: 'nagios_auto_close',
  area: 'Integration::Nagios',
  description: 'Define if tickets should be closed if service is recovered.',
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
  preferences: { prio: 3 },
  frontend: false
)
Setting.create_if_not_exists(
  title: 'Auto close state',
  name: 'nagios_auto_close_state_id',
  area: 'Integration::Nagios',
  description: 'Define the ticket state of auto closed tickets.',
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
  preferences: { prio: 4 },
  frontend: false
)

signature = Signature.create_if_not_exists(
  id: 1,
  name: 'default',
  body: '
  #{user.firstname} #{user.lastname}

--
 Super Support - Waterford Business Park
 5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
 Email: hot@example.com - Web: http://www.example.com/
--'.text2html,
  updated_by_id: 1,
  created_by_id: 1
)

Role.create_if_not_exists(
  id: 1,
  name: 'Admin',
  note: 'To configure your system.',
  updated_by_id: 1,
  created_by_id: 1
)
Role.create_if_not_exists(
  id: 2,
  name: 'Agent',
  note: 'To work on Tickets.',
  updated_by_id: 1,
  created_by_id: 1
)
Role.create_if_not_exists(
  id: 3,
  name: 'Customer',
  note: 'People who create Tickets ask for help.',
  updated_by_id: 1,
  created_by_id: 1
)
Role.create_if_not_exists(
  id: 4,
  name: 'Report',
  note: 'Access the report area.',
  created_by_id: 1,
  updated_by_id: 1,
)
Role.create_if_not_exists(
  id: 5,
  name: 'Chat',
  note: 'Access to chat feature.',
  updated_by_id: 1,
  created_by_id: 1
)

Group.create_if_not_exists(
  id: 1,
  name: 'Users',
  signature_id: signature.id,
  note: 'Standard Group/Pool for Tickets.',
  updated_by_id: 1,
  created_by_id: 1
)

user = User.create_if_not_exists(
  id: 1,
  login: '-',
  firstname: '-',
  lastname: '',
  email: '',
  password: 'root',
  active: false,
  updated_by_id: 1,
  created_by_id: 1
)

UserInfo.current_user_id = 1
roles         = Role.find_by(name: 'Customer')
organizations = Organization.all
groups        = Group.all
org_community = Organization.create_if_not_exists(
  id: 1,
  name: 'Zammad Foundation',
)
user_community = User.create_or_update(
  id: 2,
  login: 'nicole.braun@zammad.org',
  firstname: 'Nicole',
  lastname: 'Braun',
  email: 'nicole.braun@zammad.org',
  password: '',
  active: true,
  roles: [roles],
  organization_id: org_community.id,
)

Link::Type.create_if_not_exists(id: 1, name: 'normal')
Link::Object.create_if_not_exists(id: 1, name: 'Ticket')
Link::Object.create_if_not_exists(id: 2, name: 'Announcement')
Link::Object.create_if_not_exists(id: 3, name: 'Question/Answer')
Link::Object.create_if_not_exists(id: 4, name: 'Idea')
Link::Object.create_if_not_exists(id: 5, name: 'Bug')

Ticket::StateType.create_if_not_exists(id: 1, name: 'new')
Ticket::StateType.create_if_not_exists(id: 2, name: 'open')
Ticket::StateType.create_if_not_exists(id: 3, name: 'pending reminder')
Ticket::StateType.create_if_not_exists(id: 4, name: 'pending action')
Ticket::StateType.create_if_not_exists(id: 5, name: 'closed')
Ticket::StateType.create_if_not_exists(id: 6, name: 'merged')
Ticket::StateType.create_if_not_exists(id: 7, name: 'removed')

Ticket::State.create_if_not_exists(id: 1, name: 'new', state_type_id: Ticket::StateType.find_by(name: 'new').id)
Ticket::State.create_if_not_exists(id: 2, name: 'open', state_type_id: Ticket::StateType.find_by(name: 'open').id)
Ticket::State.create_if_not_exists(id: 3, name: 'pending reminder', state_type_id: Ticket::StateType.find_by(name: 'pending reminder').id, ignore_escalation: true)
Ticket::State.create_if_not_exists(id: 4, name: 'closed', state_type_id: Ticket::StateType.find_by(name: 'closed').id, ignore_escalation: true)
Ticket::State.create_if_not_exists(id: 5, name: 'merged', state_type_id: Ticket::StateType.find_by(name: 'merged').id, ignore_escalation: true)
Ticket::State.create_if_not_exists(id: 6, name: 'removed', state_type_id: Ticket::StateType.find_by(name: 'removed').id, active: false, ignore_escalation: true)
Ticket::State.create_if_not_exists(id: 7, name: 'pending close', state_type_id: Ticket::StateType.find_by(name: 'pending action').id, next_state_id: 4, ignore_escalation: true)

Ticket::Priority.create_if_not_exists(id: 1, name: '1 low')
Ticket::Priority.create_if_not_exists(id: 2, name: '2 normal')
Ticket::Priority.create_if_not_exists(id: 3, name: '3 high')

Ticket::Article::Type.create_if_not_exists(id: 1, name: 'email', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 2, name: 'sms', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 3, name: 'chat', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 4, name: 'fax', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 5, name: 'phone', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 6, name: 'twitter status', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 7, name: 'twitter direct-message', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 8, name: 'facebook feed post', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 9, name: 'facebook feed comment', communication: true)
Ticket::Article::Type.create_if_not_exists(id: 10, name: 'note', communication: false)
Ticket::Article::Type.create_if_not_exists(id: 11, name: 'web', communication: true)

Ticket::Article::Sender.create_if_not_exists(id: 1, name: 'Agent')
Ticket::Article::Sender.create_if_not_exists(id: 2, name: 'Customer')
Ticket::Article::Sender.create_if_not_exists(id: 3, name: 'System')

Macro.create_if_not_exists(
  name: 'Close & Tag as Spam',
  perform: {
    'ticket.state_id' => {
      value: Ticket::State.find_by(name: 'closed').id,
    },
    'ticket.tags' => {
      operator: 'add',
      value: 'spam',
    },
    'ticket.owner_id' => {
      pre_condition: 'current_user.id',
      value: '',
    },
  },
  note: 'example macro',
  active: true,
)

UserInfo.current_user_id = user_community.id
ticket = Ticket.create(
  group_id: Group.find_by(name: 'Users').id,
  customer_id: User.find_by(login: 'nicole.braun@zammad.org').id,
  owner_id: User.find_by(login: '-').id,
  title: 'Welcome to Zammad!',
  state_id: Ticket::State.find_by(name: 'new').id,
  priority_id: Ticket::Priority.find_by(name: '2 normal').id,
)
Ticket::Article.create(
  ticket_id: ticket.id,
  type_id: Ticket::Article::Type.find_by(name: 'phone').id,
  sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
  from: 'Zammad Feedback <feedback@zammad.org>',
  body: 'Welcome!

Thank you for choosing Zammad.

You will find updates and patches at http://zammad.org/. Online
documentation is available at http://guides.zammad.org/. You can also
use our forums at http://forums.zammad.org/

Regards,

The Zammad Project
',
  internal: false,
)

UserInfo.current_user_id = 1
overview_role = Role.find_by(name: 'Agent')
Overview.create_if_not_exists(
  name: 'My assigned Tickets',
  link: 'my_assigned',
  prio: 1000,
  role_id: overview_role.id,
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value: [ 1, 2, 3, 7 ],
    },
    'ticket.owner_id' => {
      operator: 'is',
      pre_condition: 'current_user.id',
    },
  },
  order: {
    by: 'created_at',
    direction: 'ASC',
  },
  view: {
    d: %w(title customer group created_at),
    s: %w(title customer group created_at),
    m: %w(number title customer group created_at),
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name: 'Unassigned & Open',
  link: 'all_unassigned',
  prio: 1010,
  role_id: overview_role.id,
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value: [1, 2, 3],
    },
    'ticket.owner_id' => {
      operator: 'is',
      pre_condition: 'not_set',
    },
  },
  order: {
    by: 'created_at',
    direction: 'ASC',
  },
  view: {
    d: %w(title customer group created_at),
    s: %w(title customer group created_at),
    m: %w(number title customer group created_at),
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name: 'My pending reached Tickets',
  link: 'my_pending_reached',
  prio: 1020,
  role_id: overview_role.id,
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value: 3,
    },
    'ticket.owner_id' => {
      operator: 'is',
      pre_condition: 'current_user.id',
    },
    'ticket.pending_time' => {
      operator: 'within next (relative)',
      value: 0,
      range: 'minute',
    },
  },
  order: {
    by: 'created_at',
    direction: 'ASC',
  },
  view: {
    d: %w(title customer group created_at),
    s: %w(title customer group created_at),
    m: %w(number title customer group created_at),
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name: 'Open',
  link: 'all_open',
  prio: 1030,
  role_id: overview_role.id,
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value: [1, 2, 3],
    },
  },
  order: {
    by: 'created_at',
    direction: 'ASC',
  },
  view: {
    d: %w(title customer group state owner created_at),
    s: %w(title customer group state owner created_at),
    m: %w(number title customer group state owner created_at),
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name: 'Pending reached',
  link: 'all_pending_reached',
  prio: 1040,
  role_id: overview_role.id,
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value: [3],
    },
    'ticket.pending_time' => {
      operator: 'within next (relative)',
      value: 0,
      range: 'minute',
    },
  },
  order: {
    by: 'created_at',
    direction: 'ASC',
  },
  view: {
    d: %w(title customer group owner created_at),
    s: %w(title customer group owner created_at),
    m: %w(number title customer group owner created_at),
    view_mode_default: 's',
  },
)

Overview.create_if_not_exists(
  name: 'Escalated',
  link: 'all_escalated',
  prio: 1050,
  role_id: overview_role.id,
  condition: {
    'ticket.escalation_time' => {
      operator: 'within next (relative)',
      value: '10',
      range: 'minute',
    },
  },
  order: {
    by: 'escalation_time',
    direction: 'ASC',
  },
  view: {
    d: %w(title customer group owner escalation_time),
    s: %w(title customer group owner escalation_time),
    m: %w(number title customer group owner escalation_time),
    view_mode_default: 's',
  },
)

overview_role = Role.find_by(name: 'Customer')
Overview.create_if_not_exists(
  name: 'My Tickets',
  link: 'my_tickets',
  prio: 1100,
  role_id: overview_role.id,
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value: [ 1, 2, 3, 4, 6, 7 ],
    },
    'ticket.customer_id' => {
      operator: 'is',
      pre_condition: 'current_user.id',
    },
  },
  order: {
    by: 'created_at',
    direction: 'DESC',
  },
  view: {
    d: %w(title customer state created_at),
    s: %w(number title state created_at),
    m: %w(number title state created_at),
    view_mode_default: 's',
  },
)
Overview.create_if_not_exists(
  name: 'My Organization Tickets',
  link: 'my_organization_tickets',
  prio: 1200,
  role_id: overview_role.id,
  organization_shared: true,
  condition: {
    'ticket.state_id' => {
      operator: 'is',
      value: [ 1, 2, 3, 4, 6, 7 ],
    },
    'ticket.organization_id' => {
      operator: 'is',
      pre_condition: 'current_user.organization_id',
    },
  },
  order: {
    by: 'created_at',
    direction: 'DESC',
  },
  view: {
    d: %w(title customer state created_at),
    s: %w(number title customer state created_at),
    m: %w(number title customer state created_at),
    view_mode_default: 's',
  },
)

Channel.create_if_not_exists(
  area: 'Email::Notification',
  options: {
    outbound: {
      adapter: 'smtp',
      options: {
        host: 'host.example.com',
        user: '',
        password: '',
        ssl: true,
      },
    },
  },
  group_id: 1,
  preferences: { online_service_disable: true },
  active: false,
)
Channel.create_if_not_exists(
  area: 'Email::Notification',
  options: {
    outbound: {
      adapter: 'sendmail',
    },
  },
  preferences: { online_service_disable: true },
  active: true,
)

Report::Profile.create_if_not_exists(
  name: '-all-',
  condition: {},
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)

chat = Chat.create_if_not_exists(
  name: 'default',
  max_queue: 5,
  note: '',
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)

network = Network.create_if_not_exists(
  id: 1,
  name: 'base',
)

Network::Category::Type.create_if_not_exists(
  id: 1,
  name: 'Announcement',
)
Network::Category::Type.create_if_not_exists(
  id: 2,
  name: 'Idea',
)
Network::Category::Type.create_if_not_exists(
  id: 3,
  name: 'Question',
)
Network::Category::Type.create_if_not_exists(
  id: 4,
  name: 'Bug Report',
)

Network::Privacy.create_if_not_exists(
  id: 1,
  name: 'logged in',
  key: 'loggedIn',
)
Network::Privacy.create_if_not_exists(
  id: 2,
  name: 'logged in and moderator',
  key: 'loggedInModerator',
)
Network::Category.create_if_not_exists(
  id: 1,
  name: 'Announcements',
  network_id: network.id,
  network_category_type_id: Network::Category::Type.find_by(name: 'Announcement').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in and moderator').id,
  allow_comments: true,
)
Network::Category.create_if_not_exists(
  id: 2,
  name: 'Questions',
  network_id: network.id,
  allow_comments: true,
  network_category_type_id: Network::Category::Type.find_by(name: 'Question').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in').id,
#  network_categories_moderator_user_ids: User.find_by(:login => '-').id,
)
Network::Category.create_if_not_exists(
  id: 3,
  name: 'Ideas',
  network_id: network.id,
  network_category_type_id: Network::Category::Type.find_by(name: 'Idea').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in').id,
  allow_comments: true,
)
Network::Category.create_if_not_exists(
  id: 4,
  name: 'Bug Reports',
  network_id: network.id,
  network_category_type_id: Network::Category::Type.find_by(name: 'Bug Report').id,
  network_privacy_id: Network::Privacy.find_by(name: 'logged in').id,
  allow_comments: true,
)
item = Network::Item.create(
  title: 'Example Announcement',
  body: 'Some announcement....',
  network_category_id: Network::Category.find_by(name: 'Announcements').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)
item = Network::Item.create(
  title: 'Example Question?',
  body: 'Some questions....',
  network_category_id: Network::Category.find_by(name: 'Questions').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)
item = Network::Item.create(
  title: 'Example Idea',
  body: 'Some idea....',
  network_category_id: Network::Category.find_by(name: 'Ideas').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)
item = Network::Item.create(
  title: 'Example Bug Report',
  body: 'Some bug....',
  network_category_id: Network::Category.find_by(name: 'Bug Reports').id,
)
Network::Item::Comment.create(
  network_item_id: item.id,
  body: 'Some comment....',
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'title',
  display: 'Title',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 200,
    null: false,
    translate: false,
  },
  editable: false,
  active: true,
  screens: {
    create_top: {
      '-all-' => {
        null: false,
      },
    },
    edit: {},
  },
  pending_migration: false,
  position: 15,
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'customer_id',
  display: 'Customer',
  data_type: 'user_autocompletion',
  data_option: {
    relation: 'User',
    autocapitalize: false,
    multiple: false,
    null: false,
    limit: 200,
    placeholder: 'Enter Person or Organization/Company',
    minLengt: 2,
    translate: false,
  },
  editable: false,
  active: true,
  screens: {
    create_top: {
      Agent: {
        null: false,
      },
    },
    edit: {},
  },
  pending_migration: false,
  position: 10,
)
ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'cc',
  display: 'Cc',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 1000,
    null: true,
  },
  editable: false,
  active: true,
  screens: {
    create_top: {
      Agent: {
        null: true,
      },
    },
    create_middle: {},
    edit: {}
  },
  pending_migration: false,
  position: 11,
)
ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'type',
  display: 'Type',
  data_type: 'select',
  data_option: {
    options: {
      'Incident' => 'Incident',
      'Problem'  => 'Problem',
      'Request for Change' => 'Request for Change',
    },
    nulloption: true,
    multiple: false,
    null: true,
    translate: true,
  },
  editable: false,
  active: false,
  screens: {
    create_middle: {
      '-all-' => {
        null: false,
        item_class: 'column',
      },
    },
    edit: {
      Agent: {
        null: false,
      },
    },
  },
  pending_migration: false,
  position: 20,
)
ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'group_id',
  display: 'Group',
  data_type: 'select',
  data_option: {
    relation: 'Group',
    relation_condition: { access: 'rw' },
    nulloption: true,
    multiple: false,
    null: false,
    translate: false,
    only_shown_if_selectable: true,
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {
      '-all-' => {
        null: false,
        item_class: 'column',
      },
    },
    edit: {
      Agent: {
        null: false,
      },
    },
  },
  pending_migration: false,
  position: 25,
)
ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'owner_id',
  display: 'Owner',
  data_type: 'select',
  data_option: {
    relation: 'User',
    relation_condition: { roles: 'Agent' },
    nulloption: true,
    multiple: false,
    null: true,
    translate: false,
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {
      Agent: {
        null: true,
        item_class: 'column',
      },
    },
    edit: {
      Agent: {
        null: true,
      },
    },
  },
  pending_migration: false,
  position: 30,
)
ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'state_id',
  display: 'State',
  data_type: 'select',
  data_option: {
    relation: 'TicketState',
    nulloption: true,
    multiple: false,
    null: false,
    default: 2,
    translate: true,
    filter: [1, 2, 3, 4, 7],
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {
      Agent: {
        null: false,
        item_class: 'column',
      },
      Customer: {
        item_class: 'column',
        nulloption: false,
        null: true,
        filter: [1, 4],
        default: 1,
      },
    },
    edit: {
      Agent: {
        nulloption: false,
        null: false,
        filter: [2, 3, 4, 7],
      },
      Customer: {
        nulloption: false,
        null: true,
        filter: [2, 4],
        default: 2,
      },
    },
  },
  pending_migration: false,
  position: 40,
)
ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'pending_time',
  display: 'Pending till',
  data_type: 'datetime',
  data_option: {
    future: true,
    past: false,
    diff: 24,
    null: true,
    translate: true,
    required_if: {
      state_id: [3, 7]
    },
    shown_if: {
      state_id: [3, 7]
    },
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {
      '-all-' => {
        null: false,
        item_class: 'column',
      },
    },
    edit: {
      Agent: {
        null: false,
      },
    },
  },
  pending_migration: false,
  position: 41,
)
ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'priority_id',
  display: 'Priority',
  data_type: 'select',
  data_option: {
    relation: 'TicketPriority',
    nulloption: true,
    multiple: false,
    null: false,
    default: 2,
    translate: true,
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {
      Agent: {
        null: false,
        item_class: 'column',
      },
    },
    edit: {
      Agent: {
        null: false,
        nulloption: false,
      },
    },
  },
  pending_migration: false,
  position: 80,
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'tags',
  display: 'Tags',
  data_type: 'tag',
  data_option: {
    type: 'text',
    null: true,
    translate: false,
  },
  editable: false,
  active: true,
  screens: {
    create_bottom: {
      Agent: {
        null: true,
      },
    },
    edit: {},
  },
  pending_migration: false,
  position: 900,
)

ObjectManager::Attribute.add(
  object: 'TicketArticle',
  name: 'type_id',
  display: 'Type',
  data_type: 'select',
  data_option: {
    relation: 'TicketArticleType',
    nulloption: false,
    multiple: false,
    null: false,
    default: 9,
    translate: true,
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {},
    edit: {
      Agent: {
        null: false,
      },
    },
  },
  pending_migration: false,
  position: 100,
)

ObjectManager::Attribute.add(
  object: 'TicketArticle',
  name: 'internal',
  display: 'Visibility',
  data_type: 'select',
  data_option: {
    options: { true: 'internal', false: 'public' },
    nulloption: false,
    multiple: false,
    null: true,
    default: false,
    translate: true,
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {},
    edit: {
      Agent: {
        null: false,
      },
    },
  },
  pending_migration: false,
  position: 200,
)

ObjectManager::Attribute.add(
  object: 'TicketArticle',
  name: 'to',
  display: 'To',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 1000,
    null: true,
  },
  editable: false,
  active: true,
  screens: {
    create_middle: {},
    edit: {
      Agent: {
        null: true,
      },
    },
  },
  pending_migration: false,
  position: 300,
)
ObjectManager::Attribute.add(
  object: 'TicketArticle',
  name: 'cc',
  display: 'Cc',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 1000,
    null: true,
  },
  editable: false,
  active: true,
  screens: {
    create_top: {},
    create_middle: {},
    edit: {
      Agent: {
        null: true,
      },
    },
  },
  pending_migration: false,
  position: 400,
)

ObjectManager::Attribute.add(
  object: 'TicketArticle',
  name: 'body',
  display: 'Text',
  data_type: 'richtext',
  data_option: {
    type: 'richtext',
    maxlength: 20_000,
    upload: true,
    rows: 8,
    null: true,
  },
  editable: false,
  active: true,
  screens: {
    create_top: {
      '-all-' => {
        null: false,
      },
    },
    edit: {
      Agent: {
        null: true,
      },
      Customer: {
        null: false,
      },
    },
  },
  pending_migration: false,
  position: 600,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'login',
  display: 'Login',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 100,
    null: true,
    autocapitalize: false,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {},
    view: {
      '-all-' => {
        shown: false,
      },
    },
  },
  pending_migration: false,
  position: 100,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'firstname',
  display: 'Firstname',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 150,
    null: false,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {
      '-all-' => {
        null: false,
      },
    },
    invite_agent: {
      '-all-' => {
        null: false,
      },
    },
    invite_customer: {
      '-all-' => {
        null: false,
      },
    },
    edit: {
      '-all-' => {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 200,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'lastname',
  display: 'Lastname',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 150,
    null: false,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {
      '-all-' => {
        null: false,
      },
    },
    invite_agent: {
      '-all-' => {
        null: false,
      },
    },
    invite_customer: {
      '-all-' => {
        null: false,
      },
    },
    edit: {
      '-all-' => {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 300,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'email',
  display: 'Email',
  data_type: 'input',
  data_option: {
    type: 'email',
    maxlength: 150,
    null: false,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {
      '-all-' => {
        null: false,
      },
    },
    invite_agent: {
      '-all-' => {
        null: false,
      },
    },
    invite_customer: {
      '-all-' => {
        null: false,
      },
    },
    edit: {
      '-all-' => {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 400,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'web',
  display: 'Web',
  data_type: 'input',
  data_option: {
    type: 'url',
    maxlength: 250,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 500,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'phone',
  display: 'Phone',
  data_type: 'input',
  data_option: {
    type: 'phone',
    maxlength: 100,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 600,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'mobile',
  display: 'Mobile',
  data_type: 'input',
  data_option: {
    type: 'phone',
    maxlength: 100,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 700,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'fax',
  display: 'Fax',
  data_type: 'input',
  data_option: {
    type: 'phone',
    maxlength: 100,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 800,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'organization_id',
  display: 'Organization',
  data_type: 'autocompletion_ajax',
  data_option: {
    multiple: false,
    nulloption: true,
    null: true,
    relation: 'Organization',
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {
      '-all-' => {
        null: true,
      },
    },
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 900,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'department',
  display: 'Department',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 200,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1000,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'street',
  display: 'Street',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 100,
    null: true,
  },
  editable: true,
  active: false,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1100,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'zip',
  display: 'Zip',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 100,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: true,
  active: false,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1200,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'city',
  display: 'City',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 100,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: true,
  active: false,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1300,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'address',
  display: 'Address',
  data_type: 'textarea',
  data_option: {
    type: 'text',
    maxlength: 500,
    null: true,
    item_class: 'formGroup--halfSize',
  },
  editable: true,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1350,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'password',
  display: 'Password',
  data_type: 'input',
  data_option: {
    type: 'password',
    maxlength: 100,
    null: true,
    autocomplete: 'off',
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    signup: {
      '-all-' => {
        null: false,
      },
    },
    invite_agent: {},
    invite_customer: {},
    edit: {
      Admin: {
        null: true,
      },
    },
    view: {}
  },
  pending_migration: false,
  position: 1400,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'vip',
  display: 'VIP',
  data_type: 'boolean',
  data_option: {
    null: true,
    default: false,
    item_class: 'formGroup--halfSize',
    options: {
      false: 'no',
      true: 'yes',
    },
    translate: true,
  },
  editable: false,
  active: true,
  screens: {
    edit: {
      Admin: {
        null: true,
      },
      Agent: {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: false,
      },
    },
  },
  pending_migration: false,
  position: 1490,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'note',
  display: 'Note',
  data_type: 'richtext',
  data_option: {
    type: 'text',
    maxlength: 250,
    null: true,
    note: 'Notes are visible to agents only, never to customers.',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {
      '-all-' => {
        null: true,
      },
    },
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1500,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'role_ids',
  display: 'Roles',
  data_type: 'checkbox',
  data_option: {
    multiple: true,
    null: false,
    relation: 'Role',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      Admin: {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: false,
      },
    },
  },
  pending_migration: false,
  position: 1600,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'group_ids',
  display: 'Groups',
  data_type: 'checkbox',
  data_option: {
    multiple: true,
    null: true,
    relation: 'Group',
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {
      '-all-' => {
        null: false,
        only_shown_if_selectable: true,
      },
    },
    invite_customer: {},
    edit: {
      Admin: {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: false,
      },
    },
  },
  pending_migration: false,
  position: 1700,
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'active',
  display: 'Active',
  data_type: 'active',
  data_option: {
    default: true,
  },
  editable: false,
  active: true,
  screens: {
    signup: {},
    invite_agent: {},
    invite_customer: {},
    edit: {
      Admin: {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: false,
      },
    },
  },
  pending_migration: false,
  position: 1800,
)

ObjectManager::Attribute.add(
  object: 'Organization',
  name: 'name',
  display: 'Name',
  data_type: 'input',
  data_option: {
    type: 'text',
    maxlength: 150,
    null: false,
    item_class: 'formGroup--halfSize',
  },
  editable: false,
  active: true,
  screens: {
    edit: {
      '-all-' => {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 200,
)

ObjectManager::Attribute.add(
  object: 'Organization',
  name: 'shared',
  display: 'Shared organization',
  data_type: 'boolean',
  data_option: {
    maxlength: 250,
    null: true,
    default: true,
    note: 'Customers in the organization can view each other items.',
    item_class: 'formGroup--halfSize',
    options: {
      true: 'Yes',
      false: 'No',
    }
  },
  editable: false,
  active: true,
  screens: {
    edit: {
      Admin: {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1400,
)

ObjectManager::Attribute.add(
  object: 'Organization',
  name: 'note',
  display: 'Note',
  data_type: 'richtext',
  data_option: {
    type: 'text',
    maxlength: 250,
    null: true,
    note: 'Notes are visible to agents only, never to customers.',
  },
  editable: false,
  active: true,
  screens: {
    edit: {
      '-all-' => {
        null: true,
      },
    },
    view: {
      '-all-' => {
        shown: true,
      },
    },
  },
  pending_migration: false,
  position: 1500,
)

ObjectManager::Attribute.add(
  object: 'Organization',
  name: 'active',
  display: 'Active',
  data_type: 'active',
  data_option: {
    default: true,
  },
  editable: false,
  active: true,
  screens: {
    edit: {
      Admin: {
        null: false,
      },
    },
    view: {
      '-all-' => {
        shown: false,
      },
    },
  },
  pending_migration: false,
  position: 1800,
)

Scheduler.create_if_not_exists(
  name: 'Process pending tickets',
  method: 'Ticket.process_pending',
  period: 60 * 15,
  prio: 1,
  active: true,
)
Scheduler.create_if_not_exists(
  name: 'Process escalation tickets',
  method: 'Ticket.process_escalation',
  period: 60 * 5,
  prio: 1,
  active: true,
)
Scheduler.create_if_not_exists(
  name: 'Import OTRS diff load',
  method: 'Import::OTRS.diff_worker',
  period: 60 * 3,
  prio: 1,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name: 'Check Channels',
  method: 'Channel.fetch',
  period: 30,
  prio: 1,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name: 'Check streams for Channel',
  method: 'Channel.stream',
  period: 60,
  prio: 1,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name: 'Generate Session data',
  method: 'Sessions.jobs',
  period: 60,
  prio: 1,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name: 'Execute jobs',
  method: 'Job.run',
  period: 5 * 60,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name: 'Cleanup expired sessions',
  method: 'SessionHelper.cleanup_expired',
  period: 60 * 60 * 12,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name: 'Delete old activity stream entries.',
  method: 'ActivityStream.cleanup',
  period: 1.day,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name: 'Delete old entries.',
  method: 'RecentView.cleanup',
  period: 1.day,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name: 'Delete old online notification entries.',
  method: 'OnlineNotification.cleanup',
  period: 2.hours,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name: 'Delete old token entries.',
  method: 'Token.cleanup',
  period: 30.days,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name: 'Closed chat sessions where participients are offline.',
  method: 'Chat.cleanup_close',
  period: 60 * 15,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name: 'Cleanup closed sessions.',
  method: 'Chat.cleanup',
  period: 5.days,
  prio: 2,
  active: true,
  updated_by_id: 1,
  created_by_id: 1,
)

# reset primary key sequences
if ActiveRecord::Base.connection_config[:adapter] == 'postgresql'
  ActiveRecord::Base.connection.tables.each do |t|
    ActiveRecord::Base.connection.reset_pk_sequence!(t)
  end
end

# install locales and translations
Locale.create_if_not_exists(
  locale: 'en-us',
  alias: 'en',
  name: 'English (United States)',
)
Locale.load
Translation.load
Calendar.init_setup

# install all packages in auto_install
Package.auto_install
