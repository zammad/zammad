# encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
Setting.create_if_not_exists(
  :title       => 'System Init Done',
  :name        => 'system_init_done',
  :area        => 'Core',
  :description => 'Defines if application is in init mode.',
  :options     => {},
  :state       => false,
  :frontend    => true
)
Setting.create_if_not_exists(
  :title       => 'Online Service',
  :name        => 'system_online_service',
  :area        => 'Core',
  :description => 'Defines if application is used as online service.',
  :options     => {},
  :state       => false,
  :frontend    => true
)
Setting.create_if_not_exists(
  :title       => 'Product Name',
  :name        => 'product_name',
  :area        => 'System::Base',
  :description => 'Defines the name of the application, shown in the web interface, tabs and title bar of the web browser.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'product_name',
        :tag      => 'input',
      },
    ],
  },
  :state    => 'Zammad',
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Logo',
  :name        => 'product_logo',
  :area        => 'System::CI',
  :description => 'Defines the logo of the application, shown in the web interface.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'product_logo',
        :tag      => 'input',
      },
    ],
  },
  :state    => 'logo.svg',
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'Organization',
  :name        => 'organization',
  :area        => 'System::Base',
  :description => 'Will also be included in emails as an X-Header.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'organization',
        :tag      => 'input',
      },
    ],
  },
  :state    => '',
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'SystemID',
  :name        => 'system_id',
  :area        => 'System::Base',
  :description => 'Defines the system identifier. Every ticket number contains this ID. This ensures that only tickets which belong to your system will be processed as follow-ups (useful when communicating between two instances of Zammad).',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'system_id',
        :tag      => 'select',
        :options  => {
          '10' => '10',
          '11' => '11',
          '12' => '12',
          '13' => '13',
        },
      },
    ],
  },
  :state    => '10',
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Fully Qualified Domain Name',
  :name        => 'fqdn',
  :area        => 'System::Base',
  :description => 'Defines the fully qualified domain name of the system. This setting is used as a variable, #{setting.fqdn} which is found in all forms of messaging used by the application, to build links to the tickets within your system.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'fqdn',
        :tag      => 'input',
      },
    ],
  },
  :state    => 'zammad.example.com',
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'http type',
  :name        => 'http_type',
  :area        => 'System::Base',
  :description => 'Defines the type of protocol, used by the web server, to serve the application. If https protocol will be used instead of plain http, it must be specified in here. Since this has no affect on the web server\'s settings or behavior, it will not change the method of access to the application and, if it is wrong, it will not prevent you from logging into the application. This setting is used as a variable, #{setting.http_type} which is found in all forms of messaging used by the application, to build links to the tickets within your system.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'http_type',
        :tag      => 'select',
        :options  => {
          'https' => 'https',
          'http'  => 'http',
        },
      },
    ],
  },
  :state       => 'http',
  :frontend    => true
)



Setting.create_if_not_exists(
  :title       => 'Storage Mechanism',
  :name        => 'storage',
  :area        => 'System::Storage',
  :description => '"Database" stores all attachments in the database (not recommended for storing large amounts of data). "Filesystem" stores the data on the filesystem. You can switch between the modules even on a system that is already in production without any loss of data.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'storage',
        :tag      => 'select',
        :options  => {
          'DB' => 'Database',
          'FS' => 'Filesystem',
        },
      },
    ],
  },
  :state       => 'DB',
  :frontend    => false
)
Setting.create_if_not_exists(
  :title       => 'Geo Location Backend',
  :name        => 'geo_location_backend',
  :area        => 'System::Geo',
  :description => 'Defines the backend for geo location lookups.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'geo_location_backend',
        :tag      => 'select',
        :options  => {
          '' => '-',
          'GeoLocation::Gmaps' => 'Google Maps',
        },
      },
    ],
  },
  :state    => 'GeoLocation::Gmaps',
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Geo IP Backend',
  :name        => 'geo_ip_backend',
  :area        => 'System::Geo',
  :description => 'Defines the backend for geo ip lookups.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'geo_ip_backend',
        :tag      => 'select',
        :options  => {
          '' => '-',
          'GeoIp::Freegeoip' => 'freegeoip.net',
        },
      },
    ],
  },
  :state    => 'GeoIp::Freegeoip',
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Send client stats',
  :name        => 'ui_send_client_stats',
  :area        => 'System::UI',
  :description => 'Send client stats to central server.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'ui_send_client_stats',
        :tag      => 'boolean',
        :options     => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => true,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Client storage',
  :name        => 'ui_client_storage',
  :area        => 'System::UI',
  :description => 'Use client storage to cache data to perform speed of application.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'ui_client_storage',
        :tag      => 'boolean',
        :options     => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'New User Accounts',
  :name        => 'user_create_account',
  :area        => 'Security::Base',
  :description => 'Enables users to create their own account via web interface.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'user_create_account',
        :tag      => 'boolean',
        :options     => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state       => true,
  :frontend    => true
)
Setting.create_if_not_exists(
  :title       => 'Lost Password',
  :name        => 'user_lost_password',
  :area        => 'Security::Base',
  :description => 'Activates lost password feature for agents, in the agent interface.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'user_lost_password',
        :tag      => 'boolean',
        :options     => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state       => true,
  :frontend    => true
)
Setting.create_if_not_exists(
  :title       => 'Authentication via OTRS',
  :name        => 'auth_otrs',
  :area        => 'Security::Authentication',
  :description => 'Enables user authentication via OTRS.',
  :state    => {
    :adapter           => 'Auth::Otrs',
    :required_group_ro => 'stats',
    :group_rw_role_map => {
      'admin' => 'Admin',
      'stats' => 'Report',
    },
    :group_ro_role_map => {
      'stats' => 'Report',
    },
    :always_role => {
      'Agent' => true,
    },
  },
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Authentication via LDAP',
  :name        => 'auth_ldap',
  :area        => 'Security::Authentication',
  :description => 'Enables user authentication via LDAP.',
  :state    => {
    :adapter        => 'Auth::Ldap',
    :host           => 'localhost',
    :port           => 389,
    :bind_dn        => 'cn=Manager,dc=example,dc=org',
    :bind_pw        => 'example',
    :uid            => 'mail',
    :base           => 'dc=example,dc=org',
    :always_filter  => '',
    :always_roles   => ['Admin', 'Agent'],
    :always_groups  => ['Users'],
    :sync_params    => {
      :firstname  => 'sn',
      :lastname   => 'givenName',
      :email      => 'mail',
      :login      => 'mail',
    },
  },
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Authentication via Twitter',
  :name        => 'auth_twitter',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'Enables user authentication via twitter. Register your app first at https://dev.twitter.com/apps',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'auth_twitter',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Twitter App Credentials',
  :name        => 'auth_twitter_credentials',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'App credentials for Twitter.',
  :options     => {
    :form => [
      {
        :display  => 'Twitter Key',
        :null     => true,
        :name     => 'key',
        :tag      => 'input',
      },
      {
        :display  => 'Twitter Secret',
        :null     => true,
        :name     => 'secret',
        :tag      => 'input',
      },
    ],
  },
  :state    => {},
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Authentication via Facebook',
  :name        => 'auth_facebook',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'Enables user authentication via Facebook. Register your app first at https://developers.facebook.com/apps/',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'auth_facebook',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'Facebook App Credentials',
  :name        => 'auth_facebook_credentials',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'App credentials for Facebook.',
  :options     => {
    :form => [
      {
        :display   => 'App ID',
        :null      => true,
        :name      => 'app_id',
        :tag       => 'input',
      },
      {
        :display   => 'App Secret',
        :null      => true,
        :name      => 'app_secret',
        :tag       => 'input',
      },
    ],
  },
  :state    => {},
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Authentication via Google',
  :name        => 'auth_google_oauth2',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'Enables user authentication via Google.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'auth_google_oauth2',
        :tag       => 'boolean',
        :options   => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Google App Credentials',
  :name        => 'auth_google_oauth2_credentials',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'Enables user authentication via Google.',
  :options     => {
    :form => [
      {
        :display   => 'Client ID',
        :null      => true,
        :name      => 'client_id',
        :tag       => 'input',
      },
      {
        :display   => 'Client Secret',
        :null      => true,
        :name      => 'client_secret',
        :tag       => 'input',
      },
    ],
  },
  :state    => {},
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Authentication via LinkedIn',
  :name        => 'auth_linkedin',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'Enables user authentication via LinkedIn.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'auth_linkedin',
        :tag       => 'boolean',
        :options   => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'LinkedIn App Credentials',
  :name        => 'auth_linkedin_credentials',
  :area        => 'Security::ThirdPartyAuthentication',
  :description => 'Enables user authentication via LinkedIn.',
  :options     => {
    :form => [
      {
        :display   => 'App ID',
        :null      => true,
        :name      => 'app_id',
        :tag       => 'input',
      },
      {
        :display   => 'App Secret',
        :null      => true,
        :name      => 'app_secret',
        :tag       => 'input',
      },
    ],
  },
  :state    => {},
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Minimal size',
  :name        => 'password_min_size',
  :area        => 'Security::Password',
  :description => 'Password need to have at least minimal size of characters.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'password_min_size',
        :tag       => 'select',
        :options     => {
          4 => 4,
          5 => 5,
          6 => 6,
          7 => 7,
          8 => 8,
          9 => 9,
          10 => 10,
          11 => 11,
          12 => 12,
        },
      },
    ],
  },
  :state    => 6,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => '2 lower and 2 upper characters',
  :name        => 'password_min_2_lower_2_upper_characters',
  :area        => 'Security::Password',
  :description => 'Password need to contain 2 lower and 2 upper characters.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'password_min_2_lower_2_upper_characters',
        :tag       => 'select',
        :options     => {
          1 => 'yes',
          0 => 'no',
        },
      },
    ],
  },
  :state    => 0,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Digit required',
  :name        => 'password_need_digit',
  :area        => 'Security::Password',
  :description => 'Password need to have at least one digit.',
  :options     => {
    :form => [
      {
        :display   => 'Needed',
        :null      => true,
        :name      => 'password_need_digit',
        :tag       => 'select',
        :options     => {
          1 => 'yes',
          0 => 'no',
        },
      },
    ],
  },
  :state    => 0,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Maximal failed logins',
  :name        => 'password_max_login_failed',
  :area        => 'Security::Password',
  :description => 'Maximal failed logins after account is inactive.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'password_max_login_failed',
        :tag       => 'select',
        :options     => {
          4 => 4,
          5 => 5,
          6 => 6,
          7 => 7,
          8 => 8,
          9 => 9,
          10 => 10,
          11 => 11,
          13 => 13,
          14 => 14,
          15 => 15,
          16 => 16,
          17 => 17,
          18 => 18,
          19 => 19,
          20 => 20,
        },
      },
    ],
  },
  :state    => 10,
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'Ticket Hook',
  :name        => 'ticket_hook',
  :area        => 'Ticket::Base',
  :description => 'The identifier for a ticket, e.g. Ticket#, Call#, MyTicket#. The default is Ticket#.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => false,
        :name      => 'ticket_hook',
        :tag       => 'input',
      },
    ],
  },
  :state    => 'Ticket#',
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Ticket Hook Divider',
  :name        => 'ticket_hook_divider',
  :area        => 'Ticket::Base::Shadow',
  :description => 'The divider between TicketHook and ticket number. E.g \': \'.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'ticket_hook_divider',
        :tag       => 'input',
      },
    ],
  },
  :state    => '',
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Ticket Hook Position',
  :name        => 'ticket_hook_position',
  :area        => 'Ticket::Base',
  :description => 'The format of the subject. "Left" means "[Ticket#12345] Some Subject", "Right" means "Some Subject [Ticket#12345]", "None" means "Some Subject" and no ticket number. In the last case you should enable PostmasterFollowupSearchInRaw or PostmasterFollowUpSearchInReferences to recognize followups based on email headers and/or body.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'ticket_hook_position',
        :tag       => 'select',
        :options     => {
          'left'  => 'Left',
          'right' => 'Right',
          'none'  => 'None',
        },
      },
    ],
  },
  :state    => 'right',
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Ticket Subject Size',
  :name        => 'ticket_subject_size',
  :area        => 'Ticket::Base',
  :description => 'Max size of the subjects in an email reply.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => false,
        :name      => 'ticket_subject_size',
        :tag       => 'input',
      },
    ],
  },
  :state    => '110',
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Ticket Subject Reply',
  :name        => 'ticket_subject_re',
  :area        => 'Ticket::Base',
  :description => 'The text at the beginning of the subject in an email reply, e.g. RE, AW, or AS.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'ticket_subject_re',
        :tag       => 'input',
      },
    ],
  },
  :state    => 'RE',
  :frontend => false
)
#Setting.create(
#  :title       => 'Ticket Subject Forward',
#  :name        => 'ticket_subject_fw',
#  :area        => 'Ticket::Base',
#  :description => 'The text at the beginning of the subject when an email is forwarded, e.g. FW, Fwd, or WG.',
#  :state       => {
#    :value => 'FW',
#  },
#  :frontend    => false
#)

Setting.create_if_not_exists(
  :title       => 'Ticket Number Format',
  :name        => 'ticket_number',
  :area        => 'Ticket::Number',
  :description => 'Selects the ticket number generator module. "Increment" increments the ticket
 number, the SystemID and the counter are used with SystemID.Counter format (e.g. 1010138, 1010139).
 With "Date" the ticket numbers will be generated by the current date, the SystemID and the counter.
 The format looks like Year.Month.Day.SystemID.counter (e.g. 201206231010138, 201206231010139).
 With param "Checksum => true" the counter will be appended as checksum to the string. The format 
 looks like SystemID.Counter.CheckSum (e. g. 10101384, 10101392) or Year.Month.Day.SystemID.Counter.CheckSum (e.g. 2012070110101520, 2012070110101535).',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'ticket_number',
        :tag       => 'select',
        :options   => {
          'Ticket::Number::Increment' => 'Increment (SystemID.Counter)',
          'Ticket::Number::Date'      => 'Date (Year.Month.Day.SystemID.Counter)',
        },
      },
    ],
  },
  :state    => 'Ticket::Number::Increment',
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Ticket Number Increment',
  :name        => 'ticket_number_increment',
  :area        => 'Ticket::Number',
  :description => '-',
  :options     => {
    :form => [
      {
        :display  => 'Checksum',
        :null     => true,
        :name     => 'checksum',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
      {
        :display  => 'Min. size of number',
        :null     => true,
        :name     => 'min_size',
        :tag      => 'select',
        :options  => {
          1 => 1,
          2 => 2,
          3 => 3,
          4 => 4,
          5 => 5,
          6 => 6,
          7 => 7,
          8 => 8,
          9 => 9,
          10 => 10,
          11 => 11,
          12 => 12,
          13 => 13,
          14 => 14,
          15 => 15,
          16 => 16,
          17 => 17,
          18 => 18,
          19 => 19,
          20 => 20,
        },
      },
    ],
  },
  :state => {
    :checksum => false,
    :min_size => 5,
  },
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Ticket Number Increment Date',
  :name        => 'ticket_number_date',
  :area        => 'Ticket::Number',
  :description => '-',
  :options     => {
    :form => [
      {
        :display  => 'Checksum',
        :null     => true,
        :name     => 'checksum',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state => {
    :checksum => false,
  },
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Enable Ticket creation',
  :name        => 'customer_ticket_create',
  :area        => 'CustomerWeb::Base',
  :description => 'Defines if a customer can create tickets via the web interface.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'customer_ticket_create',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => true,
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'Group selection for Ticket creation',
  :name        => 'customer_ticket_create_group_ids',
  :area        => 'CustomerWeb::Base',
  :description => 'Defines groups where customer can create tickets via web interface. "-" means all groups are available.',
  :options     => {
    :form => [
      {
        :display    => '',
        :null       => true,
        :name       => 'group_ids',
        :tag        => 'select',
        :multiple   => true,
        :null       => false,
        :nulloption => true,
        :relation   => 'Group',
      },
    ],
  },
  :state    => '',
  :frontend => true
)


Setting.create_if_not_exists(
  :title       => 'Enable Ticket View/Update',
  :name        => 'customer_ticket_view',
  :area        => 'CustomerWeb::Base',
  :description => 'Defines if a customer view and update his own tickets.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'customer_ticket_view',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => true,
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'Sender Format',
  :name        => 'ticket_define_email_from',
  :area        => 'Email::Base',
  :description => 'Defines how the From field from the emails (sent from answers and email tickets) should look like.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'ticket_define_email_from',
        :tag       => 'select',
        :options   => {
          :SystemAddressName          => 'System Address Display Name',
          :AgentNameSystemAddressName => 'Agent Name + FromSeparator + System Address Display Name',
        },
      },
    ],
  },
  :state    => 'SystemAddressName',
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Sender Format Seperator',
  :name        => 'ticket_define_email_from_seperator',
  :area        => 'Email::Base',
  :description => 'Defines the separator between the agents real name and the given group email address.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'ticket_define_email_from_seperator',
        :tag      => 'input',
      },
    ],
  },
  :state    => 'via',
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Max. Email Size',
  :name        => 'postmaster_max_size',
  :area        => 'Email::Base',
  :description => 'Maximal size in MB of emails.',
  :options     => {
    :form => [
      {
        :display   => '',
        :null      => true,
        :name      => 'postmaster_max_size',
        :tag       => 'select',
        :options   => {
          1 => 1,
          2 => 2,
          3 => 3,
          4 => 4,
          5 => 5,
          6 => 6,
          7 => 7,
          8 => 8,
          9 => 9,
          10 => 10,
          11 => 11,
          12 => 12,
          13 => 13,
          14 => 14,
          15 => 15,
          16 => 16,
          17 => 17,
          18 => 18,
          19 => 19,
          20 => 20,
        },
      },
    ],
  },
  :state    => 10,
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Additional follow up detection',
  :name        => 'postmaster_follow_up_search_in',
  :area        => 'Email::Base',
  :description => '"References" - Executes follow up checks on In-Reply-To or References headers for mails that don\'t have a ticket number in the subject. "Body" - Executes follow up mail body checks in mails that don\'t have a ticket number in the subject. "Attachment" - Executes follow up mail attachments checks in mails that don\'t have a ticket number in the subject. "Raw" - Executes follow up plain/raw mail checks in mails that don\'t have a ticket number in the subject.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'postmaster_follow_up_search_in',
        :tag      => 'checkbox',
        :options  => {
          'references' => 'References',
          'body'       => 'Body',
          'attachment' => 'Attachment',
          'raw'        => 'Raw',
        },
      },
    ],
  },
  :state    => ['subject'],
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Notification Sender',
  :name        => 'notification_sender',
  :area        => 'Email::Base',
  :description => 'Defines the sender of email notifications.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'notification_sender',
        :tag      => 'input',
      },
    ],
  },
  :state    => 'Notification Master <noreply@#{config.fqdn}>',
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Block Notifications',
  :name        => 'send_no_auto_response_reg_exp',
  :area        => 'Email::Base',
  :description => 'If this regex matches, no notification will be send by the sender.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'send_no_auto_response_reg_exp',
        :tag      => 'input',
      },
    ],
  },
  :state    => '(MAILER-DAEMON|postmaster|abuse)@.+?\..+?',
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Enable Chat',
  :name        => 'chat',
  :area        => 'Chat::Base',
  :description => 'Enable/Disable online chat.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'chat',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'Default Screen',
  :name        => 'default_controller',
  :area        => 'Core',
  :description => 'Defines the default controller.',
  :options     => {},
  :state       => '#dashboard',
  :frontend    => true
)

Setting.create_if_not_exists(
  :title       => 'Import Mode',
  :name        => 'import_mode',
  :area        => 'Import::Base',
  :description => 'Set system in import mode (disable some triggers).',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'import_mode',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)
Setting.create_if_not_exists(
  :title       => 'Import Backend',
  :name        => 'import_backend',
  :area        => 'Import::Base::Internal',
  :description => 'Set backend which is used for import.',
  :options     => {},
  :state       => '',
  :frontend    => true
)
Setting.create_if_not_exists(
  :title       => 'Ignore Escalation/SLA Information',
  :name        => 'import_ignore_sla',
  :area        => 'Import::Base',
  :description => 'Ignore Escalation/SLA Information form import system.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'import_ignore_sla',
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state    => false,
  :frontend => true
)

Setting.create_if_not_exists(
  :title       => 'Import Endpoint',
  :name        => 'import_otrs_endpoint',
  :area        => 'Import::OTRS',
  :description => 'Defines OTRS endpoint to import users, ticket, states and articles.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'import_otrs_endpoint',
        :tag      => 'input',
      },
    ],
  },
  :state    => 'http://otrs_host/otrs',
  :frontend => false
)
Setting.create_if_not_exists(
  :title       => 'Import Key',
  :name        => 'import_otrs_endpoint_key',
  :area        => 'Import::OTRS',
  :description => 'Defines OTRS endpoint auth key.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'import_otrs_endpoint_key',
        :tag      => 'input',
      },
    ],
  },
  :state    => '',
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Import User for http basic authentiation',
  :name        => 'import_otrs_user',
  :area        => 'Import::OTRS',
  :description => 'Defines http basic authentiation user (only if OTRS is protected via http basic auth).',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'import_otrs_user',
        :tag      => 'input',
      },
    ],
  },
  :state    => '',
  :frontend => false
)

Setting.create_if_not_exists(
  :title       => 'Import Password for http basic authentiation',
  :name        => 'import_otrs_password',
  :area        => 'Import::OTRS',
  :description => 'Defines http basic authentiation password (only if OTRS is protected via http basic auth).',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'import_otrs_password',
        :tag      => 'input',
      },
    ],
  },
  :state    => '',
  :frontend => false
)


email_address = EmailAddress.create_if_not_exists(
  :id             => 1,
  :realname       => 'Zammad',
  :email          => 'zammad@localhost',
  :updated_by_id  => 1,
  :created_by_id  => 1
)
signature = Signature.create_if_not_exists(
  :name => 'default',
  :body => '
  #{user.firstname} #{user.lastname}

--
 Super Support - Waterford Business Park
 5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
 Email: hot@example.com - Web: http://www.example.com/
--',
  :updated_by_id  => 1,
  :created_by_id  => 1
)

Role.create_if_not_exists(
  :id             => 1,
  :name           => 'Admin',
  :note           => 'To configure your system.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)
Role.create_if_not_exists(
  :id             => 2,
  :name           => 'Agent',
  :note           => 'To work on Tickets.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)
Role.create_if_not_exists(
  :id             => 3,
  :name           => 'Customer',
  :note           => 'People who create Tickets ask for help.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)

Group.create_if_not_exists(
  :id               => 1,
  :name             => 'Users',
  :email_address_id => email_address.id,
  :signature_id     => signature.id,
  :note             => 'Standard Group/Pool for Tickets.',
  :updated_by_id    => 1,
  :created_by_id    => 1
)

user = User.create_if_not_exists(
  :login         => '-',
  :firstname     => '-',
  :lastname      => '',
  :email         => '',
  :password      => 'root',
  :active        => false,
  :updated_by_id => 1,
  :created_by_id => 1
)

UserInfo.current_user_id = 1
roles         = Role.where( :name => 'Customer' )
organizations = Organization.all
groups        = Group.all
org_community = Organization.create_if_not_exists(
  :name => 'Zammad Foundation',
)
user_community = User.create_or_update(
  :login           => 'nicole.braun@zammad.org',
  :firstname       => 'Nicole',
  :lastname        => 'Braun',
  :email           => 'nicole.braun@zammad.org',
  :password        => '',
  :active          => true,
  :roles           => roles,
  :organization_id => org_community.id,
)

Link::Type.create_if_not_exists( :name => 'normal' )
Link::Object.create_if_not_exists( :name => 'Ticket' )
Link::Object.create_if_not_exists( :name => 'Announcement' )
Link::Object.create_if_not_exists( :name => 'Question/Answer' )
Link::Object.create_if_not_exists( :name => 'Idea' )
Link::Object.create_if_not_exists( :name => 'Bug' )

Ticket::StateType.create_if_not_exists( :id => 1, :name => 'new', :updated_by_id  => 1 )
Ticket::StateType.create_if_not_exists( :id => 2, :name => 'open', :updated_by_id  => 1 )
Ticket::StateType.create_if_not_exists( :id => 3, :name => 'pending reminder', :updated_by_id  => 1 )
Ticket::StateType.create_if_not_exists( :id => 4, :name => 'pending action', :updated_by_id  => 1 )
Ticket::StateType.create_if_not_exists( :id => 5, :name => 'closed', :updated_by_id  => 1 )
Ticket::StateType.create_if_not_exists( :id => 6, :name => 'merged', :updated_by_id  => 1 )
Ticket::StateType.create_if_not_exists( :id => 7, :name => 'removed', :updated_by_id  => 1 )

Ticket::State.create_if_not_exists( :id => 1, :name => 'new', :state_type_id => Ticket::StateType.where(:name => 'new').first.id )
Ticket::State.create_if_not_exists( :id => 2, :name => 'open', :state_type_id => Ticket::StateType.where(:name => 'open').first.id )
Ticket::State.create_if_not_exists( :id => 3, :name => 'pending', :state_type_id => Ticket::StateType.where(:name => 'pending reminder').first.id  )
Ticket::State.create_if_not_exists( :id => 4, :name => 'closed', :state_type_id  => Ticket::StateType.where(:name => 'closed').first.id  )
Ticket::State.create_if_not_exists( :id => 5, :name => 'merged', :state_type_id  => Ticket::StateType.where(:name => 'merged').first.id  )
Ticket::State.create_if_not_exists( :id => 6, :name => 'removed', :state_type_id  => Ticket::StateType.where(:name => 'removed').first.id  )

Ticket::Priority.create_if_not_exists( :name => '1 low' )
Ticket::Priority.create_if_not_exists( :name => '2 normal' )
Ticket::Priority.create_if_not_exists( :name => '3 high' )

Ticket::Article::Type.create_if_not_exists( :name => 'email', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'sms', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'chat', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'fax', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'phone', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'twitter status', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'twitter direct-message', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'facebook', :communication => true )
Ticket::Article::Type.create_if_not_exists( :name => 'note', :communication => false )
Ticket::Article::Type.create_if_not_exists( :name => 'web', :communication => true )

Ticket::Article::Sender.create_if_not_exists( :name => 'Agent' )
Ticket::Article::Sender.create_if_not_exists( :name => 'Customer' )
Ticket::Article::Sender.create_if_not_exists( :name => 'System' )

UserInfo.current_user_id = user_community.id
ticket = Ticket.create(
  :group_id    => Group.where( :name => 'Users' ).first.id,
  :customer_id => User.where( :login => 'nicole.braun@zammad.org' ).first.id,
  :owner_id    => User.where( :login => '-' ).first.id,
  :title       => 'Welcome to Zammad!',
  :state_id    => Ticket::State.where( :name => 'new' ).first.id,
  :priority_id => Ticket::Priority.where( :name => '2 normal' ).first.id,
)
Ticket::Article.create(
  :ticket_id => ticket.id,
  :type_id   => Ticket::Article::Type.where(:name => 'phone' ).first.id,
  :sender_id => Ticket::Article::Sender.where(:name => 'Customer' ).first.id,
  :from      => 'Zammad Feedback <feedback@zammad.org>',
  :body      => 'Welcome!

Thank you for installing Zammad.

You will find updates and patches at http://zammad.org/. Online
documentation is available at http://guides.zammad.org/. You can also
use our forums at http://forums.zammad.org/

Regards,

The Zammad.org Project
',
  :internal                 => false,
)

UserInfo.current_user_id = 1
overview_role = Role.where( :name => 'Agent' ).first
Overview.create_if_not_exists(
  :name       => 'My assigned Tickets',
  :link       => 'my_assigned',
  :prio       => 1000,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [ 1,2,3 ],
    'tickets.owner_id' => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'group', 'created_at' ],
    :s => [ 'title', 'customer', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'My pending reached Tickets',
  :link       => 'my_pending_reached',
  :prio       => 1010,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [3],
    'tickets.owner_id' => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'group', 'created_at' ],
    :s => [ 'title', 'customer', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'Unassigned & Open Tickets',
  :link       => 'all_unassigned',
  :prio       => 1020,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [1,2,3],
    'tickets.owner_id' => 1,
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'group', 'created_at' ],
    :s => [ 'title', 'customer', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'All Open Tickets',
  :link       => 'all_open',
  :prio       => 1030,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [1,2,3],
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'group', 'created_at' ],
    :s => [ 'title', 'customer', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
)

Overview.create_if_not_exists(
  :name       => 'Escalated Tickets',
  :link       => 'all_escalated',
  :prio       => 1040,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.escalation_time' =>{ 'direction' => 'before', 'count'=> 5, 'area' => 'minute' },
  },
  :order => {
    :by        => 'escalation_time',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'group', 'owner', 'escalation_time' ],
    :s => [ 'title', 'customer', 'group', 'owner', 'escalation_time' ],
    :m => [ 'number', 'title', 'customer', 'group', 'owner', 'escalation_time' ],
    :view_mode_default => 's',
  },
)

overview_role = Role.where( :name => 'Customer' ).first
Overview.create_if_not_exists(
  :name       => 'My Tickets',
  :link       => 'my_tickets',
  :prio       => 1000,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.state_id' => [ 1,2,3,4,6 ],
    'tickets.customer_id'     => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'created_at' ],
    :s => [ 'number', 'title', 'state', 'created_at' ],
    :m => [ 'number', 'title', 'state', 'created_at' ],
    :view_mode_default => 's',
  },
)
Overview.create_if_not_exists(
  :name                => 'My Organization Tickets',
  :link                => 'my_organization_tickets',
  :prio                => 1100,
  :role_id             => overview_role.id,
  :organization_shared => true,
  :condition => {
    'tickets.state_id' => [ 1,2,3,4,6 ],
    'tickets.organization_id' => 'current_user.organization_id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :view => {
    :d => [ 'title', 'customer', 'state', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'state', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'state', 'created_at' ],
    :view_mode_default => 's',
  },
)

Channel.create_if_not_exists(
  :adapter => 'SMTP',
  :area    => 'Email::Outbound',
  :options => {
    :host     => 'host.example.com',
    :user     => '',
    :password => '',
    :ssl      => true,
  },
  :group_id       => 1,
  :active         => false,
)
Channel.create_if_not_exists(
  :adapter        => 'Sendmail',
  :area           => 'Email::Outbound',
  :options        => {},
  :active         => true,
)

network = Network.create_if_not_exists(
  :name   => 'base',
)

Network::Category::Type.create_if_not_exists(
  :name   => 'Announcement',
)
Network::Category::Type.create_if_not_exists(
  :name => 'Idea',
)
Network::Category::Type.create_if_not_exists(
  :name => 'Question',
)
Network::Category::Type.create_if_not_exists(
  :name => 'Bug Report',
)

Network::Privacy.create_if_not_exists(
  :name => 'logged in',
  :key  => 'loggedIn',
)
Network::Privacy.create_if_not_exists(
  :name => 'logged in and moderator',
  :key  => 'loggedInModerator',
)
Network::Category.create_if_not_exists(
  :name                     => 'Announcements',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Announcement').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in and moderator').first.id,
  :allow_comments           => true,
)
Network::Category.create_if_not_exists(
  :name                     => 'Questions',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Question').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
#  :network_categories_moderator_user_ids => User.where(:login => '-').first.id,
)
Network::Category.create_if_not_exists(
  :name                     => 'Ideas',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Idea').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
  :allow_comments           => true,
)
Network::Category.create_if_not_exists(
  :name                     => 'Bug Reports',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Bug Report').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
  :allow_comments           => true,
)
item = Network::Item.create(
  :title                => 'Example Announcement',
  :body                 => 'Some announcement....',
  :network_category_id  => Network::Category.where(:name => 'Announcements').first.id,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
)
item = Network::Item.create(
  :title                => 'Example Question?',
  :body                 => 'Some questions....',
  :network_category_id  => Network::Category.where(:name => 'Questions').first.id,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
)
item = Network::Item.create(
  :title                => 'Example Idea',
  :body                 => 'Some idea....',
  :network_category_id  => Network::Category.where(:name => 'Ideas').first.id,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
)
item = Network::Item.create(
  :title                => 'Example Bug Report',
  :body                 => 'Some bug....',
  :network_category_id  => Network::Category.where(:name => 'Bug Reports').first.id,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
)

Translation.create_if_not_exists( :locale => 'de', :source => "New", :target => "Neu" )
Translation.create_if_not_exists( :locale => 'de', :source => "Create", :target => "Erstellen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Cancel", :target => "Abbrechen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Submit", :target => "Übermitteln" )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign out", :target => "Abmelden" )
Translation.create_if_not_exists( :locale => 'de', :source => "Profile", :target => "Profil" )
Translation.create_if_not_exists( :locale => 'de', :source => "Settings", :target => "Einstellungen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Overviews", :target => "Übersichten" )
Translation.create_if_not_exists( :locale => 'de', :source => "Manage", :target => "Verwalten" )
Translation.create_if_not_exists( :locale => 'de', :source => "Users", :target => "Benutzer" )
Translation.create_if_not_exists( :locale => 'de', :source => "User", :target => "Benutzer" )
Translation.create_if_not_exists( :locale => 'de', :source => "Groups", :target => "Gruppen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Group", :target => "Gruppe" )
Translation.create_if_not_exists( :locale => 'de', :source => "Organizations", :target => "Organisationen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Organization", :target => "Organisation" )
Translation.create_if_not_exists( :locale => 'de', :source => "Recent Viewed", :target => "Zuletzt angesehen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Security", :target => "Sicherheit" )
Translation.create_if_not_exists( :locale => 'de', :source => "From", :target => "Von" )
Translation.create_if_not_exists( :locale => 'de', :source => "Title", :target => "Titel" )
Translation.create_if_not_exists( :locale => 'de', :source => "Customer", :target => "Kunde" )
Translation.create_if_not_exists( :locale => 'de', :source => "State", :target => "Status" )
Translation.create_if_not_exists( :locale => 'de', :source => "Created", :target => "Erstellt" )
Translation.create_if_not_exists( :locale => 'de', :source => "Attributes", :target => "Attribute" )
Translation.create_if_not_exists( :locale => 'de', :source => "Direction", :target => "Richtung" )
Translation.create_if_not_exists( :locale => 'de', :source => "Owner", :target => "Besitzer" )
Translation.create_if_not_exists( :locale => 'de', :source => "Subject", :target => "Betreff" )
Translation.create_if_not_exists( :locale => 'de', :source => "Priority", :target => "Priorität" )
Translation.create_if_not_exists( :locale => 'de', :source => "Select the customer of the ticket or create one.", :target => "Wähle den Kunden f�r das Ticket oder erstelle einen Neuen." )
Translation.create_if_not_exists( :locale => 'de', :source => "New Ticket", :target => "Neues Ticket" )
Translation.create_if_not_exists( :locale => 'de', :source => "Firstname", :target => "Vorname" )
Translation.create_if_not_exists( :locale => 'de', :source => "Lastname", :target => "Nachname" )
Translation.create_if_not_exists( :locale => 'de', :source => "Phone", :target => "Telefon" )
Translation.create_if_not_exists( :locale => 'de', :source => "Street", :target => "Straße" )
Translation.create_if_not_exists( :locale => 'de', :source => "Zip", :target => "PLZ" )
Translation.create_if_not_exists( :locale => 'de', :source => "City", :target => "Stadt" )
Translation.create_if_not_exists( :locale => 'de', :source => "Note", :target => "Notiz" )
Translation.create_if_not_exists( :locale => 'de', :source => "note", :target => "Notiz" )
Translation.create_if_not_exists( :locale => 'de', :source => "New User", :target => "Neuer Benutzer" )
Translation.create_if_not_exists( :locale => 'de', :source => "Merge", :target => "Zusammenfügen" )
Translation.create_if_not_exists( :locale => 'de', :source => "History", :target => "Historie" )
Translation.create_if_not_exists( :locale => 'de', :source => "new", :target => "neu" )
Translation.create_if_not_exists( :locale => 'de', :source => "closed", :target => "geschlossen" )
Translation.create_if_not_exists( :locale => 'de', :source => "close", :target => "schließen" )
Translation.create_if_not_exists( :locale => 'de', :source => "open", :target => "offen" )
Translation.create_if_not_exists( :locale => 'de', :source => "pending", :target => "warten" )
Translation.create_if_not_exists( :locale => 'de', :source => "merged", :target => "zusammengefügt" )
Translation.create_if_not_exists( :locale => 'de', :source => "removed", :target => "zurück gezogen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Activity Stream", :target => "Aktivitäts-Stream" )
Translation.create_if_not_exists( :locale => 'de', :source => "Update", :target => "Aktualisieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "updated", :target => "aktualisierte" )
Translation.create_if_not_exists( :locale => 'de', :source => "created", :target => "erstellte" )
Translation.create_if_not_exists( :locale => 'de', :source => "My assigned Tickets", :target => "Meine zugewiesenen Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "Unassigned Tickets", :target => "Nicht zugewiesene/freie Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "Unassigned & Open Tickets", :target => "Nicht zugewiesene & offene Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "All Tickets", :target => "Alle Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "Escalated Tickets", :target => "Eskalierte Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "My pending reached Tickets", :target => "Meine warten erreicht Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "Password", :target => "Passwort" )
Translation.create_if_not_exists( :locale => 'de', :source => "Password (confirm)", :target => "Passwort (bestätigen)" )
Translation.create_if_not_exists( :locale => 'de', :source => "Role", :target => "Rolle" )
Translation.create_if_not_exists( :locale => 'de', :source => "Roles", :target => "Rollen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Active", :target => "Aktiv" )
Translation.create_if_not_exists( :locale => 'de', :source => "Edit", :target => "Bearbeiten" )
Translation.create_if_not_exists( :locale => 'de', :source => "Base", :target => "Basis" )
Translation.create_if_not_exists( :locale => 'de', :source => "Number", :target => "Nummer" )
Translation.create_if_not_exists( :locale => 'de', :source => "Sender Format", :target => "Absender Format" )
Translation.create_if_not_exists( :locale => 'de', :source => "Authentication", :target => "Authorisierung" )
Translation.create_if_not_exists( :locale => 'de', :source => "Product Name", :target => "Produkt Name" )
Translation.create_if_not_exists( :locale => 'de', :source => "To", :target => "An" )
Translation.create_if_not_exists( :locale => 'de', :source => "Customer", :target => "Kunde" )
Translation.create_if_not_exists( :locale => 'de', :source => "Linked Accounts", :target => "Verknüpfte Accounts" )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign in with", :target => "Anmelden mit" )
Translation.create_if_not_exists( :locale => 'de', :source => "Username or email", :target => "Benutzer oder E-Mail" )
Translation.create_if_not_exists( :locale => 'de', :source => "Remember me", :target => "An mich erinnern" )
Translation.create_if_not_exists( :locale => 'de', :source => "Forgot password?", :target => "Passwort vergessen?" )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign in using", :target => "Anmelden über" )
Translation.create_if_not_exists( :locale => 'de', :source => "New to", :target => "Neu bei" )
Translation.create_if_not_exists( :locale => 'de', :source => "join today!", :target => "werde Teil!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign up", :target => "Registrieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign in", :target => "Anmelden" )
Translation.create_if_not_exists( :locale => 'de', :source => "Create my account", :target => "Meinen Account erstellen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Login successfully! Have a nice day!", :target => "Anmeldung erfolgreich!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Last contact", :target => "Letzter Kontakt" )
Translation.create_if_not_exists( :locale => 'de', :source => "Last contact (Agent)", :target => "Letzter Kontakt (Agent)" )
Translation.create_if_not_exists( :locale => 'de', :source => "Last contact (Customer)", :target => "Letzter Kontakt (Kunde)" )
Translation.create_if_not_exists( :locale => 'de', :source => "Close time", :target => "Schließzeit" )
Translation.create_if_not_exists( :locale => 'de', :source => "First response", :target => "Erste Reaktion" )
Translation.create_if_not_exists( :locale => 'de', :source => "Ticket %s created!", :target => "Ticket %s erstellt!" )
Translation.create_if_not_exists( :locale => 'de', :source => "day", :target => "Tag" )
Translation.create_if_not_exists( :locale => 'de', :source => "days", :target => "Tagen" )
Translation.create_if_not_exists( :locale => 'de', :source => "hour", :target => "Stunde" )
Translation.create_if_not_exists( :locale => 'de', :source => "hours", :target => "Stunden" )
Translation.create_if_not_exists( :locale => 'de', :source => "minute", :target => "Minute" )
Translation.create_if_not_exists( :locale => 'de', :source => "minutes", :target => "Minuten" )
Translation.create_if_not_exists( :locale => 'de', :source => "See more", :target => "mehr anzeigen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Search", :target => "Suche" )
Translation.create_if_not_exists( :locale => 'de', :source => "Forgot your password?", :target => "Passwort vergessen?" )
Translation.create_if_not_exists( :locale => 'de', :source => "Templates", :target => "Vorlagen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Delete", :target => "Löschen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Apply", :target => "Übernehmen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Save as Template", :target => "Als Vorlage speichern" )
Translation.create_if_not_exists( :locale => 'de', :source => "Save", :target => "Speichern" )
Translation.create_if_not_exists( :locale => 'de', :source => "Open Tickets", :target => "Offene Ticket" )
Translation.create_if_not_exists( :locale => 'de', :source => "Closed Tickets", :target => "Geschlossene Ticket" )
Translation.create_if_not_exists( :locale => 'de', :source => "set to internal", :target => "auf intern setzen" )
Translation.create_if_not_exists( :locale => 'de', :source => "set to public", :target => "auf öffentlich setzen" )
Translation.create_if_not_exists( :locale => 'de', :source => "split", :target => "teilen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Type", :target => "Typ" )
Translation.create_if_not_exists( :locale => 'de', :source => "raw", :target => "unverarbeitet" )
Translation.create_if_not_exists( :locale => 'de', :source => "1 low", :target => "1 niedrig" )
Translation.create_if_not_exists( :locale => 'de', :source => "2 normal", :target => "2 normal" )
Translation.create_if_not_exists( :locale => 'de', :source => "3 high", :target => "3 hoch" )
Translation.create_if_not_exists( :locale => 'de', :source => "public", :target => "öffentlich" )
Translation.create_if_not_exists( :locale => 'de', :source => "internal", :target => "intern" )
Translation.create_if_not_exists( :locale => 'de', :source => "Attach files", :target => "Dateien anhängen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Visibility", :target => "Sichtbarkeit" )
Translation.create_if_not_exists( :locale => 'de', :source => "Actions", :target => "Aktionen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Email", :target => "E-Mail" )
Translation.create_if_not_exists( :locale => 'de', :source => "email", :target => "E-Mail" )
Translation.create_if_not_exists( :locale => 'de', :source => "phone", :target => "Telefon" )
Translation.create_if_not_exists( :locale => 'de', :source => "fax", :target => "Fax" )
Translation.create_if_not_exists( :locale => 'de', :source => "chat", :target => "Chat" )
Translation.create_if_not_exists( :locale => 'de', :source => "sms", :target => "SMS" )
Translation.create_if_not_exists( :locale => 'de', :source => "twitter status", :target => "Twitter Status Meldung" )
Translation.create_if_not_exists( :locale => 'de', :source => "twitter direct-message", :target => "Twitter Direkt-Nachricht" )
Translation.create_if_not_exists( :locale => 'de', :source => "All Open Tickets", :target => "Alle offenen Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "child", :target => "Kind" )
Translation.create_if_not_exists( :locale => 'de', :source => "parent", :target => "Eltern" )
Translation.create_if_not_exists( :locale => 'de', :source => "normal", :target => "Normal" )
Translation.create_if_not_exists( :locale => 'de', :source => "Linked Objects", :target => "Verknüpfte Objekte" )
Translation.create_if_not_exists( :locale => 'de', :source => "Links", :target => "Verknüpftungen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Change Customer", :target => "Kunden ändern" )
Translation.create_if_not_exists( :locale => 'de', :source => "My Tickets", :target => "Meine Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "My Organization Tickets", :target => "Meine Organisations Tickets" )
Translation.create_if_not_exists( :locale => 'de', :source => "My Organization", :target => "Meine Organisation" )
Translation.create_if_not_exists( :locale => 'de', :source => "Assignment Timeout", :target => "Zeitliche Zuweisungsüberschritung" )
Translation.create_if_not_exists( :locale => 'de', :source => "We've sent password reset instructions to your email address.", :target => "Wir haben Ihnen die Anleitung zum zurücksetzen Ihres Passworts an Ihre E-Mail-Adresse gesendet." )
Translation.create_if_not_exists( :locale => 'de', :source => "Enter your username or email address", :target => "Bitte geben Sie Ihren Benutzernamen oder E-Mail-Adresse ein" )
Translation.create_if_not_exists( :locale => 'de', :source => "Choose your new password.", :target => "Wählen Sie Ihr neues Passwort." )
Translation.create_if_not_exists( :locale => 'de', :source => "Woo hoo! Your password has been changed!", :target => "Vielen Dank, Ihr Passwort wurde geändert!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Please try to login!", :target => "Bitte melden Sie sich nun an!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Username or email address invalid, please try again.", :target => "Benutzername oder E-Mail-Addresse ungültig, bitte erneut versuchen." )
Translation.create_if_not_exists( :locale => 'de', :source => "If you don\'t receive instructions within a minute or two, check your email\'s spam and junk filters, or try resending your request.", :target => "Wir haben die Anforderung per E-Mail an Sie versendet, bitte überprüfen Sie Ihr E-Mail-Postfach (auch die Junk E-Mails) ggf. starten Sie eine Anforderung erneut." )
Translation.create_if_not_exists( :locale => 'de', :source => "again", :target => "erneut" )
Translation.create_if_not_exists( :locale => 'de', :source => "none", :target => "keine" )
Translation.create_if_not_exists( :locale => 'de', :source => "Welcome!", :target => "Willkommen!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Please click the button below to create your first one.", :target => "Klicken Sie die Schaltfläche unten um das erste zu erstellen." )
Translation.create_if_not_exists( :locale => 'de', :source => "Create your first Ticket", :target => "Erstellen Sie Ihr erstes Ticket" )
Translation.create_if_not_exists( :locale => 'de', :source => "You have not created a Ticket yet.", :target => "Sie haben noch kein Ticket erstellt." )
Translation.create_if_not_exists( :locale => 'de', :source => "The way to communicate with us is this thing called \"Ticket\".", :target => "Der Weg um mit uns zu kommunizieren ist das sogenannte \"Ticket\"." )
Translation.create_if_not_exists( :locale => 'de', :source => "or", :target => "oder" )
Translation.create_if_not_exists( :locale => 'de', :source => "yes", :target => "ja" )
Translation.create_if_not_exists( :locale => 'de', :source => "no", :target => "nein" )
Translation.create_if_not_exists( :locale => 'de', :source => "Attachment", :target => "Anhang" )
Translation.create_if_not_exists( :locale => 'de', :source => "Year", :target => "Jahr" )
Translation.create_if_not_exists( :locale => 'de', :source => "Month", :target => "Monat" )
Translation.create_if_not_exists( :locale => 'de', :source => "Day", :target => "Tag" )
Translation.create_if_not_exists( :locale => 'de', :source => "Closed", :target => "Geschlossen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Re-Open", :target => "Wiedereröffnet" )
Translation.create_if_not_exists( :locale => 'de', :source => "Day", :target => "Tag" )
Translation.create_if_not_exists( :locale => 'de', :source => "First Solution", :target => "Erstlösung" )
Translation.create_if_not_exists( :locale => 'de', :source => "Vendor", :target => "Hersteller" )
Translation.create_if_not_exists( :locale => 'de', :source => "Action", :target => "Aktion" )
Translation.create_if_not_exists( :locale => 'de', :source => "uninstall", :target => "deinstallieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "install", :target => "installieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "reinstall", :target => "erneut installieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "deactivate", :target => "deaktivieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "activate", :target => "aktivieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "uninstalled", :target => "deinstalliert" )
Translation.create_if_not_exists( :locale => 'de', :source => "installed", :target => "installiert" )
Translation.create_if_not_exists( :locale => 'de', :source => "deactivated", :target => "deaktiviert" )
Translation.create_if_not_exists( :locale => 'de', :source => "activated", :target => "aktiviert" )
Translation.create_if_not_exists( :locale => 'de', :source => "new", :target => "neu" )
Translation.create_if_not_exists( :locale => 'de', :source => "note", :target => "Notiz" )
Translation.create_if_not_exists( :locale => 'de', :source => "phone", :target => "Telefon" )
Translation.create_if_not_exists( :locale => 'de', :source => "web", :target => "Web" )
Translation.create_if_not_exists( :locale => 'de', :source => "Change order", :target => "Reihenfolge ändern" )
Translation.create_if_not_exists( :locale => 'de', :source => "Group by", :target => "Gruppieren mit" )
Translation.create_if_not_exists( :locale => 'de', :source => "Items per page", :target => "Einträge je Seite" )
Translation.create_if_not_exists( :locale => 'de', :source => "Last Contact", :target => "Letzter Kontakt" )
Translation.create_if_not_exists( :locale => 'de', :source => "Last Contact Agent", :target => "Letzter Kontakt Agent" )
Translation.create_if_not_exists( :locale => 'de', :source => "Last Contact Customer", :target => "Letzter Kontakt Kunde" )
Translation.create_if_not_exists( :locale => 'de', :source => "Create an inbound Ticket", :target => "Erstelle ein eingehendes Ticket" )
Translation.create_if_not_exists( :locale => 'de', :source => "Create an outbound Ticket (will send this as email to customer)", :target => "Erstelle ein ausgehendes Ticket (wird per E-Mail an den Kunden gesendet)" )
Translation.create_if_not_exists( :locale => 'de', :source => "Age", :target => "Alter" )
Translation.create_if_not_exists( :locale => 'de', :source => "Article Count", :target => "Artikel Anzahl" )
Translation.create_if_not_exists( :locale => 'de', :source => "Article", :target => "Artikel" )
Translation.create_if_not_exists( :locale => 'de', :source => "Close Time", :target => "Schließzeit" )
Translation.create_if_not_exists( :locale => 'de', :source => "First Response", :target => "Erste Reaktion" )
Translation.create_if_not_exists( :locale => 'de', :source => "up", :target => "auf" )
Translation.create_if_not_exists( :locale => 'de', :source => "down", :target => "ab" )
Translation.create_if_not_exists( :locale => 'de', :source => "Inbound", :target => "Eingehend" )
Translation.create_if_not_exists( :locale => 'de', :source => "Outbound", :target => "Ausgehend" )
Translation.create_if_not_exists( :locale => 'de', :source => "Adresses", :target => "Adressen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Signatures", :target => "Signatur" )
Translation.create_if_not_exists( :locale => 'de', :source => "Filter", :target => "Filter" )
Translation.create_if_not_exists( :locale => 'de', :source => "Bulk-Action executed!", :target => "Sammelaktion ausgeführt!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Moved in", :target => "Hinein Verschoben" )
Translation.create_if_not_exists( :locale => 'de', :source => "Moved out", :target => "Heraus Verschoben" )
Translation.create_if_not_exists( :locale => 'de', :source => "Country", :target => "Land" )
Translation.create_if_not_exists( :locale => 'de', :source => "Invitation sent!", :target => "Einladung versendet" )
Translation.create_if_not_exists( :locale => 'de', :source => "Can't create user", :target => "Benutzer konnte nicht angelegt werden!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Update successful!", :target => "Aktualisierung erfolgreich!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Invite Agents", :target => "Agenten einladen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Getting started!", :target => "Ersten Schritte!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Create Admin", :target => "Admin erstellen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Configure Channels", :target => "Kanäle konfigurieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "Send invitation", :target => "Einladung senden" )
Translation.create_if_not_exists( :locale => 'de', :source => "Next...", :target => "Weiter..." )
Translation.create_if_not_exists( :locale => 'de', :source => "Week", :target => "Woche" )
Translation.create_if_not_exists( :locale => 'de', :source => "Follow up possible", :target => "Nachfrage möglich" )
Translation.create_if_not_exists( :locale => 'de', :source => "Assign Follow Ups", :target => "Zuweisung bei Nachfrage" )
Translation.create_if_not_exists( :locale => 'de', :source => "Signature", :target => "Signatur" )
Translation.create_if_not_exists( :locale => 'de', :source => "Change your password", :target => "Ändern Sie Ihr Passwort" )
Translation.create_if_not_exists( :locale => 'de', :source => "Current Password", :target => "Aktuelles Passwort" )
Translation.create_if_not_exists( :locale => 'de', :source => "New Password", :target => "Neues Passwort" )
Translation.create_if_not_exists( :locale => 'de', :source => "New Password (confirm)", :target => "Neues Passwort (bestätigen)" )
Translation.create_if_not_exists( :locale => 'de', :source => "Language", :target => "Sprache" )
Translation.create_if_not_exists( :locale => 'de', :source => "Link Accounts", :target => "Verknüpfte Accounts" )
Translation.create_if_not_exists( :locale => 'de', :source => "Change your language.", :target => "Ändern Sie Ihr Sprache." )
Translation.create_if_not_exists( :locale => 'de', :source => "Successfully!", :target => "Erfolgreich!" )
Translation.create_if_not_exists( :locale => 'de', :source => "Remove", :target => "Entfernen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Add", :target => "Hinzufügen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Call Outbound", :target => "Anruf ausgehend" )
Translation.create_if_not_exists( :locale => 'de', :source => "Call Inbound", :target => "Anruf eingehend" )
Translation.create_if_not_exists( :locale => 'de', :source => "Loading...", :target => "Laden..." )
Translation.create_if_not_exists( :locale => 'de', :source => "Work Disposition", :target => "Arbeitsverteilung" )
Translation.create_if_not_exists( :locale => 'de', :source => "Timezone", :target => "Zeitzone" )
Translation.create_if_not_exists( :locale => 'de', :source => "Business Times", :target => "Arbeitszeiten" )
Translation.create_if_not_exists( :locale => 'de', :source => "Day", :target => "Day" )
Translation.create_if_not_exists( :locale => 'de', :source => "Days", :target => "Days" )
Translation.create_if_not_exists( :locale => 'de', :source => "Hour", :target => "Stunde" )
Translation.create_if_not_exists( :locale => 'de', :source => "Hours", :target => "Stunden" )
Translation.create_if_not_exists( :locale => 'de', :source => "New SLA", :target => "Neuer SLA" )
Translation.create_if_not_exists( :locale => 'de', :source => "Conditions where SLA is used", :target => "Bedingungen bei denen der SLA verwendet wird" )
Translation.create_if_not_exists( :locale => 'de', :source => "First Response Time", :target => "Reaktionszeit" )
Translation.create_if_not_exists( :locale => 'de', :source => "Update Time", :target => "Aktuallisierungszeit" )
Translation.create_if_not_exists( :locale => 'de', :source => "Solution Time", :target => "Lösungszeit" )
Translation.create_if_not_exists( :locale => 'de', :source => "Add Attribute", :target => "Attribut hinzufügen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Back to top", :target => "Nach oben" )
Translation.create_if_not_exists( :locale => 'de', :source => "Discard your unsaved changes.", :target => "Verwerfen der ungespeicherten Änderungen." )
Translation.create_if_not_exists( :locale => 'de', :source => "Copy to clipboard: Ctrl+C, Enter", :target => "In die Zwischenablage kopieren: Strg+C, Return" )
Translation.create_if_not_exists( :locale => 'de', :source => "Copy to clipboard", :target => "In die Zwischenablage kopieren" )
Translation.create_if_not_exists( :locale => 'de', :source => "Send to clients", :target => "An Clients senden" )
Translation.create_if_not_exists( :locale => 'de', :source => "Feedback about our new Interface", :target => "Feedback übers neue Design!" )
Translation.create_if_not_exists( :locale => 'de', :source => "What ideas do you have?", :target => "Welche Ideen haben Sie?" )
Translation.create_if_not_exists( :locale => 'de', :source => "Attach Screenshot of page", :target => "Screenshot dieser Seite anhängen" )
Translation.create_if_not_exists( :locale => 'de', :source => "Thanks for your Feedback!", :target => "Vielen Dank für Ihre Feedback!" )
Translation.create_if_not_exists( :locale => 'de', :source => "What can you do here?", :target => "Was können Sie hier machen?" )
Translation.create_if_not_exists( :locale => 'de', :source => "Here you can create one.", :target => "Hier können Sie eins erstellen." )
Translation.create_if_not_exists( :locale => 'de', :source => "Fold in", :target => "Einklappen" )
Translation.create_if_not_exists( :locale => 'de', :source => "from", :target => "von" )
Translation.create_if_not_exists( :locale => 'de', :source => "to", :target => "nach" )
Translation.create_if_not_exists( :locale => 'de', :source => "%s ago", :target => "vor %s" )
Translation.create_if_not_exists( :locale => 'de', :source => "in %s", :target => "in %s" )
#Translation.create_if_not_exists( :locale => 'de', :source => "", :target => "" )

# install all packages in auto_install
Package.auto_install()
