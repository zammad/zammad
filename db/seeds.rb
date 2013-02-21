# encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
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
  :state    => 'Example Inc.',
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
  :description => 'Defines the type of protocol, used by the web server, to serve the application. If https protocol will be used instead of plain http, it must be specified it here. Since this has no affect on the web server\'s settings or behavior, it will not change the method of access to the application and, if it is wrong, it will not prevent you from logging into the application. This setting is used as a variable, #{setting.http_type} which is found in all forms of messaging used by the application, to build links to the tickets within your system.',
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
  :description => '"Database" stores all attachments in the database (not recommended for storing big). "Filesystem" stores the data on the filesystem; this is faster but the webserver should run under the Zammad user. You can switch between the modules even on a system that is already in production without any loss of data.',
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
  :title       => 'Switch to User',
  :name        => 'switch_to_user',
  :area        => 'Security::Base',
  :description => 'Allows the administrators to login as other users, via the users administration panel.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'switch_to_user', 
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
  :title       => 'Authentication via OTRS',
  :name        => 'auth_otrs',
  :area        => 'Security::Authentication',
  :description => 'Enables user authentication via OTRS.',
  :state    => {
    :adapter           => 'otrs',
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
    :adapter        => 'ldap',
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
  :state    => 'left',
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
          'increment' => 'Increment (SystemID.Counter)',
          'date'      => 'Date (Year.Month.Day.SystemID.Counter)',
        },
      },
    ],
  },
  :state    => 'increment',
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
  :title       => 'Import Endpoint',
  :name        => 'import_otrs_endpoint',
  :area        => 'Import::OTRS',
  :description => 'Defines OTRS endpoint to import users, ticket, ticket_states and articles.',
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
  :frontend => true
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
  :frontend => true
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
Group.create_if_not_exists(
  :id             => 2,
  :name           => 'Twitter',
  :note           => 'All Tweets.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)

roles         = Role.where( :name => 'Customer' )
organizations = Organization.find( :all )
groups        = Group.find( :all )

user = User.create_if_not_exists(
  :login         => '-',
  :firstname     => '-',
  :lastname      => '',
  :email         => '',
  :password      => 'root',
  :active        => false,
  :roles         => roles,
  :groups        => groups,
  :organizations => organizations,
  :updated_by_id => 1,
  :created_by_id => 1
)
user_community = User.create_if_not_exists(
  :login         => 'nicole.braun@zammad.org',
  :firstname     => 'Nicole',
  :lastname      => 'Braun',
  :email         => 'nicole.braun@zammad.org',
  :password      => '',
  :active        => true,
  :roles         => roles,
#  :groups        => groups,
  :organizations => organizations,
  :updated_by_id => 1,
  :created_by_id => 1
)

Link::Type.create_if_not_exists( :name => 'normal' )
Link::Object.create_if_not_exists( :name => 'Ticket' )
Link::Object.create_if_not_exists( :name => 'Announcement' )
Link::Object.create_if_not_exists( :name => 'Question/Answer' )
Link::Object.create_if_not_exists( :name => 'Idea' )
Link::Object.create_if_not_exists( :name => 'Bug' )

Ticket::StateType.create_if_not_exists( :name => 'new', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create_if_not_exists( :name => 'open', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create_if_not_exists( :name => 'pending reminder', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create_if_not_exists( :name => 'pending action', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create_if_not_exists( :name => 'closed', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create_if_not_exists( :name => 'merged', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create_if_not_exists( :name => 'removed', :updated_by_id  => 1, :created_by_id => 1 )

Ticket::State.create_if_not_exists( :name => 'new', :state_type_id => Ticket::StateType.where(:name => 'new').first.id, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::State.create_if_not_exists( :name => 'open', :state_type_id => Ticket::StateType.where(:name => 'open').first.id, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::State.create_if_not_exists( :name => 'pending', :state_type_id => Ticket::StateType.where(:name => 'pending reminder').first.id, :updated_by_id  => 1, :created_by_id => 1  )
Ticket::State.create_if_not_exists( :name => 'closed', :state_type_id  => Ticket::StateType.where(:name => 'closed').first.id, :updated_by_id  => 1, :created_by_id => 1  )
Ticket::State.create_if_not_exists( :name => 'merged', :state_type_id  => Ticket::StateType.where(:name => 'merged').first.id, :updated_by_id  => 1, :created_by_id => 1  )
Ticket::State.create_if_not_exists( :name => 'removed', :state_type_id  => Ticket::StateType.where(:name => 'removed').first.id, :updated_by_id  => 1, :created_by_id => 1  )

Ticket::Priority.create_if_not_exists( :name => '1 low', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Priority.create_if_not_exists( :name => '2 normal', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Priority.create_if_not_exists( :name => '3 high', :updated_by_id  => 1, :created_by_id => 1 )

Ticket::Article::Type.create_if_not_exists( :name => 'email', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'sms', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'chat', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'fax', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'phone', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'twitter status', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'twitter direct-message', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'facebook', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'note', :communication => false, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create_if_not_exists( :name => 'web', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )

Ticket::Article::Sender.create_if_not_exists( :name => 'Agent', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Sender.create_if_not_exists( :name => 'Customer', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Sender.create_if_not_exists( :name => 'System', :updated_by_id  => 1, :created_by_id => 1 )

ticket = Ticket.create(
  :group_id           => Group.where( :name => 'Users' ).first.id,
  :customer_id        => User.where( :login => 'nicole.braun@zammad.org' ).first.id,
  :owner_id           => User.where( :login => '-' ).first.id,
  :title              => 'Welcome to Zammad!',
  :ticket_state_id    => Ticket::State.where( :name => 'new' ).first.id,
  :ticket_priority_id => Ticket::Priority.where( :name => '2 normal' ).first.id,
  :updated_by_id      => User.where( :login => 'nicole.braun@zammad.org' ).first.id,
  :created_by_id      => User.where( :login => 'nicole.braun@zammad.org' ).first.id
)
Ticket::Article.create(
  :ticket_id                => ticket.id, 
  :ticket_article_type_id   => Ticket::Article::Type.where(:name => 'phone' ).first.id,
  :ticket_article_sender_id => Ticket::Article::Sender.where(:name => 'Customer' ).first.id,
  :from                     => 'Zammad Feedback <feedback@zammad.org>',
  :body                     => 'Welcome!

Thank you for installing Zammad.

You will find updates and patches at http://zammad.org/. Online
documentation is available at http://guides.zammad.org/. You can also
use our forums at http://forums.zammad.org/

Regards,

The Zammad.org Project
',
  :internal                 => false,
  :updated_by_id            => User.where( :login => 'nicole.braun@zammad.org' ).first.id,
  :created_by_id            => User.where( :login => 'nicole.braun@zammad.org' ).first.id
)

overview_role = Role.where( :name => 'Agent' ).first
Overview.create_if_not_exists(
  :name       => 'My assigned Tickets',
  :link       => 'my_assigned',
  :prio       => 1000,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.ticket_state_id' => [ 1,2,3 ],
    'tickets.owner_id'        => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'ticket_state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create_if_not_exists(
  :name       => 'Unassigned & Open Tickets',
  :link       => 'all_unassigned',
  :prio       => 1001,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.ticket_state_id' => [1,2,3],
    'tickets.owner_id'        => 1,
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'ticket_state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create_if_not_exists(
  :name       => 'All Open Tickets',
  :link       => 'all_open',
  :prio       => 1002,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.ticket_state_id' => [1,2,3],
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'ticket_state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create_if_not_exists(
  :name       => 'Escalated Tickets',
  :link       => 'all_escalated',
  :prio       => 1010,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.ticket_state_id' => [1,2,3],
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'ticket_state', 'group', 'owner', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'owner', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'owner', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create_if_not_exists(
  :name       => 'My pending reached Tickets',
  :link       => 'my_pending_reached',
  :prio       => 1020,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.ticket_state_id' => [3],
    'tickets.owner_id'        => 'current_user.id',        
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :d => [ 'title', 'customer', 'ticket_state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create_if_not_exists(
  :name       => 'All Tickets',
  :link       => 'all',
  :prio       => 9003,
  :role_id    => overview_role.id,
  :condition  => {
#      'tickets.ticket_state_id' => [3],
#      'tickets.owner_id'        => current_user.id,        
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :view => {
    :s => [ 'title', 'customer', 'ticket_state', 'group', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :m => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

overview_role = Role.where( :name => 'Customer' ).first
Overview.create_if_not_exists(
  :name       => 'My Tickets',
  :link       => 'my_tickets',
  :prio       => 1000,
  :role_id    => overview_role.id,
  :condition  => {
    'tickets.ticket_state_id' => [ 1,2,3,4,6 ],
    'tickets.customer_id'     => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :view => {
    :d => [ 'title', 'customer', 'ticket_state', 'created_at' ],
    :s => [ 'number', 'title', 'ticket_state', 'ticket_priority', 'created_at' ],
    :m => [ 'number', 'title', 'ticket_state', 'ticket_priority', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)
Overview.create_if_not_exists(
  :name                => 'My Organization Tickets',
  :link                => 'my_organization_tickets',
  :prio                => 1100,
  :role_id             => overview_role.id,
  :organization_shared => true,
  :condition => {
    'tickets.ticket_state_id' => [ 1,2,3,4,6 ],
    'tickets.organization_id' => 'current_user.organization_id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :view => {
    :d => [ 'title', 'customer', 'ticket_state', 'created_at' ],
    :s => [ 'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'created_at' ],
    :m => [ 'number', 'title', 'ticket_state', 'ticket_priority', 'created_at' ],
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
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
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Channel.create_if_not_exists(
  :adapter        => 'Sendmail',
  :area           => 'Email::Outbound',
  :options        => {},
  :active         => true,
  :updated_by_id  => 1,
  :created_by_id  => 1,
)

network = Network.create_if_not_exists(
  :name   => 'base',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)

Network::Category::Type.create_if_not_exists(
  :name   => 'Announcement',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category::Type.create_if_not_exists(
  :name => 'Idea',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category::Type.create_if_not_exists(
  :name => 'Question',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category::Type.create_if_not_exists(
  :name => 'Bug Report',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)

Network::Privacy.create_if_not_exists(
  :name => 'logged in',
  :key  => 'loggedIn',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Privacy.create_if_not_exists(
  :name => 'logged in and moderator',
  :key  => 'loggedInModerator',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category.create_if_not_exists(
  :name                     => 'Announcements',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Announcement').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in and moderator').first.id,
  :allow_comments           => true,
  :updated_by_id            => 1,
  :created_by_id            => 1,
)
Network::Category.create_if_not_exists(
  :name                     => 'Questions',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Question').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
#  :network_categories_moderator_user_ids => User.where(:login => '-').first.id,
  :updated_by_id            => 1,
  :created_by_id            => 1,
)
Network::Category.create_if_not_exists(
  :name                     => 'Ideas',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Idea').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
  :allow_comments           => true,
  :updated_by_id            => 1,
  :created_by_id            => 1,
)
Network::Category.create_if_not_exists(
  :name                     => 'Bug Reports',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Bug Report').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
  :allow_comments           => true,
  :updated_by_id            => 1,
  :created_by_id            => 1,
)
item = Network::Item.create(
  :title                => 'Example Announcement',
  :body                 => 'Some announcement....',
  :network_category_id  => Network::Category.where(:name => 'Announcements').first.id,
  :updated_by_id        => 1,
  :created_by_id        => 1,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :updated_by_id    => 1,
  :created_by_id    => 1,
)
item = Network::Item.create(
  :title                => 'Example Question?',
  :body                 => 'Some questions....',
  :network_category_id  => Network::Category.where(:name => 'Questions').first.id,
  :updated_by_id        => 1,
  :created_by_id        => 1,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :updated_by_id    => 1,
  :created_by_id    => 1,
)
item = Network::Item.create(
  :title                => 'Example Idea',
  :body                 => 'Some idea....',
  :network_category_id  => Network::Category.where(:name => 'Ideas').first.id,
  :updated_by_id        => 1,
  :created_by_id        => 1,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :updated_by_id    => 1,
  :created_by_id    => 1,
)
item = Network::Item.create(
  :title                => 'Example Bug Report',
  :body                 => 'Some bug....',
  :network_category_id  => Network::Category.where(:name => 'Bug Reports').first.id,
  :updated_by_id        => 1,
  :created_by_id        => 1,
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :updated_by_id    => 1,
  :created_by_id    => 1,
)

Translation.create_if_not_exists( :locale => 'de', :source => "New", :target => "Neu", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Create", :target => "Erstellen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Cancel", :target => "Abbrechen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Submit", :target => "Übermitteln", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign out", :target => "Abmelden", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Profile", :target => "Profil", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Settings", :target => "Einstellungen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Overviews", :target => "Übersichten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Manage", :target => "Verwalten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Users", :target => "Benutzer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Groups", :target => "Gruppen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Group", :target => "Gruppe", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Organizations", :target => "Organisationen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Organization", :target => "Organisation", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Recent Viewed", :target => "Zuletzt angesehen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Security", :target => "Sicherheit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "From", :target => "Von", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Title", :target => "Titel", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Customer", :target => "Kunde", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "State", :target => "Status", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Created", :target => "Erstellt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Attributes", :target => "Attribute", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Direction", :target => "Richtung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Owner", :target => "Besitzer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Subject", :target => "Betreff", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Priority", :target => "Priorität", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Select the customer of the Ticket or create one.", :target => "Wähle den Kundn f�r das Ticket oder erstell einen neuen.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "New Ticket", :target => "Neues Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Firstname", :target => "Vorname", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Lastname", :target => "Nachname", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Phone", :target => "Telefon", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Street", :target => "Straße", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Zip", :target => "PLZ", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "City", :target => "Stadt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Note", :target => "Notiz", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "note", :target => "Notiz", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "New User", :target => "Neuer Benutzer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Merge", :target => "Zusammenfügen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "History", :target => "Historie", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "new", :target => "neu", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "closed", :target => "geschlossen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "open", :target => "offen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "pending", :target => "warten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "merged", :target => "zusammengefügt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "removed", :target => "zurück gezogen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Activity Stream", :target => "Aktivitäts-Stream", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "updated", :target => "aktuallisierte", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "created", :target => "erstellte", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "My assigned Tickets", :target => "Meine zugewisenen Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Unassigned Tickets", :target => "Nicht zugewisene/freie Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Unassigned & Open Tickets", :target => "Nicht zugewisene & offene Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "All Tickets", :target => "Alle Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Escalated Tickets", :target => "Eskallierte Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "My pending reached Tickets", :target => "Meine warten erreicht Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Password", :target => "Passwort", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Password (confirm)", :target => "Passwort (bestätigen)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Role", :target => "Rolle", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Roles", :target => "Rollen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Active", :target => "Aktiv", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Edit", :target => "Bearbeiten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Base", :target => "Basis", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Number", :target => "Nummer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Sender Format", :target => "Absender Format", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Authentication", :target => "Authorisierung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Product Name", :target => "Produkt Name", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "To", :target => "An", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Customer", :target => "Kunde", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Linked Accounts", :target => "Verknüpfte Accounts", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign in with", :target => "Anmelden mit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Username or email", :target => "Benutzer oder Email", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Remember me", :target => "An mich erinnern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Forgot password?", :target => "Passwort vergessen?", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign in using", :target => "Anmelden über", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "New to", :target => "Neu bei", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "join today!", :target => "werde Teil!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign up", :target => "Registrieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Sign in", :target => "Anmelden", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Create my account", :target => "Meinen Account erstellen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Login successfully! Have a nice day!", :target => "Anmeldung erfolgreich!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Last contact", :target => "Letzter Kontakt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Last contact (Agent)", :target => "Letzter Kontakt (Agent)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Last contact (Customer)", :target => "Letzter Kontakt (Kunde)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Close time", :target => "Schließzeit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "First response", :target => "Erste Reaktion", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Ticket %s created!", :target => "Ticket %s erstellt!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "day", :target => "Tag", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "days", :target => "Tage", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "hour", :target => "Stunde", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "hours", :target => "Stunden", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "minute", :target => "Minute", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "minutes", :target => "Minuten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "See more", :target => "mehr anzeigen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Search", :target => "Suche", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Forgot your password?", :target => "Passwort vergessen?", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Templates", :target => "Vorlagen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Delete", :target => "Löschen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Apply", :target => "Übernehmen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Save as Template", :target => "Als Template speichern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Save", :target => "Speichern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Open Tickets", :target => "Offene Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Closed Tickets", :target => "Geschlossene Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "set to internal", :target => "auf intern setzen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "set to public", :target => "auf öffentlich setzen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "split", :target => "teilen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Type", :target => "Typ", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "raw", :target => "unverarbeitet", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "1 low", :target => "1 niedrig", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "2 normal", :target => "2 normal", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "3 high", :target => "3 hoch", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "public", :target => "öffentlich", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "internal", :target => "intern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Attach files", :target => "Dateien anhängen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Visability", :target => "Sichtbarkeit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Actions", :target => "Aktionen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Email", :target => "E-Mail", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "email", :target => "E-Mail", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "phone", :target => "Telefon", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "fax", :target => "Fax", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "chat", :target => "Chat", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "sms", :target => "SMS", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "twitter status", :target => "Twitter Status Meldung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "twitter direct-message", :target => "Twitter Direkt-Nachricht", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "All Open Tickets", :target => "Alle offenen Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "child", :target => "Kind", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "parent", :target => "Eltern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "normal", :target => "Normal", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Linked Objects", :target => "Verknüpfte Objekte", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Links", :target => "Verknüpftungen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Change Customer", :target => "Kunden ändern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "My Tickets", :target => "Meine Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "My Organization Tickets", :target => "Meine Organisations Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "My Organization", :target => "Meine Organisation", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Assignment Timout", :target => "Zeitliche Zuweisungsüberschritung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "We've sent password reset instructions to your email address.", :target => "Wir haben Ihnen die Anleitung zum zurücksetzen Ihres Passworts an Ihre E-Mail-Adresse gesendet.", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Enter your username or email address", :target => "Bitte geben Sie Ihren Benutzernamen oder E-Mail-Adresse ein", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Choose your new password.", :target => "Wählen Sie Ihr neues Passwort.", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Woo hoo! Your password has been changed!", :target => "Vielen Dank, Ihr Passwort wurde geändert!", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Please try to login!", :target => "Bitte melden Sie sich nun an!", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Username or email address invalid, please try again.", :target => "Benutzername oder E-Mail-Addresse ungültig, bitte erneut versuchen.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "If you don\'t receive instructions within a minute or two, check your email\'s spam and junk filters, or try resending your request.", :target => "Wir haben die Anforderung per E-Mail an Sie versendet, bitte überprüfen Sie Ihr Email-Postfach (auch die Junk E-Mails) ggf. starten Sie eine Anforderung erneut.", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "again", :target => "erneut", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "none", :target => "keine", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Welcome!", :target => "Willkommen!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Please click the button below to create your first one.", :target => "Klicken Sie die Schaltfläche unten um das erste zu erstellen.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Create your first Ticket", :target => "Erstellen Sie Ihr erstes Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "You have not created a Ticket yet.", :target => "Sie haben noch kein Ticket erstellt.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "The way to communicate with us is this thing called \"Ticket\".", :target => "Der Weg um mit uns zu kommunizieren ist das sogenannte \"Ticket\".", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "or", :target => "oder", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "yes", :target => "ja", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "no", :target => "nein", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Attachment", :target => "Anhang", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Year", :target => "Jahr", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Month", :target => "Monat", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Day", :target => "Tag", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Closed", :target => "Geschlossen", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Re-Open", :target => "Wiedereröffnet", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Day", :target => "Tag", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "First Solution", :target => "Erstlösung", :updated_by_id => 1, :created_by_id => 1 )
Translation.create_if_not_exists( :locale => 'de', :source => "Vendor", :target => "Hersteller", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Action", :target => "Aktion", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "uninstall", :target => "deinstallieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "install", :target => "installieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "reinstall", :target => "erneut installieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "deactivate", :target => "deaktivieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "activate", :target => "aktivieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "uninstalled", :target => "deinstalliert", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "installed", :target => "installiert", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "deactivated", :target => "deaktiviert", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "activated", :target => "aktiviert", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "new", :target => "neu", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "note", :target => "Notiz", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "phone", :target => "Telefon", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "web", :target => "Web", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Change order", :target => "Reihenfolge ändern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Group by", :target => "Gruppieren mit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Items per page", :target => "Einträge je Seite", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Last Contact", :target => "Letzter Kontakt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Last Contact Agent", :target => "Letzter Kontakt Agent", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Last Contact Customer", :target => "Letzter Kontakt Kunde", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Create an inbound Ticket", :target => "Erstelle ein eingehendes Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Create an outbound Ticket (will send this as email to customer)", :target => "Erstelle ein ausgehendes Ticket (wird per E-Mail an den Kunden gesendet)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Age", :target => "Alter", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Article Count", :target => "Artikel Anzahl", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Article", :target => "Artikel", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Close Time", :target => "Schließzeit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "First Response", :target => "Erste Reaktion", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "up", :target => "auf", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "down", :target => "ab", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Inbound", :target => "Eingehend", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Outbound", :target => "Ausgehend", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Adresses", :target => "Adressen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Signatures", :target => "Signatur", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Filter", :target => "Filter", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Bulk-Action executed!", :target => "Sammelaktion ausgeführt!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Moved in", :target => "Hinein Verschoben", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Moved out", :target => "Heraus Verschoben", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Country", :target => "Land", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Invitation sent!", :target => "Einladung versendet", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Can't create user", :target => "Benutzer konnte nicht angelegt werden!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Update successful!", :target => "Aktualisierung erfolgreich!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Invite Agents", :target => "Agenten einladen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Getting started!", :target => "Ersten Schritte!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Create Admin", :target => "Admin erstellen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Configure Channels", :target => "Kanäle konfigurieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Send invitation", :target => "Einladung senden", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Next...", :target => "Weiter...", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Week", :target => "Woche", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Follow up possible", :target => "Nachfrage möglich", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Assign Follow Ups", :target => "Zuweisung bei Nachfrage", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Signature", :target => "Signatur", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Change your password", :target => "Ändern Sie Ihr Passwort", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Current Password", :target => "Aktuelles Passwort", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "New Password", :target => "Neues Passwort", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "New Password (confirm)", :target => "Neues Passwort (bestätigen)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Language", :target => "Sprache", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Link Accounts", :target => "Verknüpfte Accounts", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Change your language.", :target => "Ändern Sie Ihr Sprache.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Successfully!", :target => "Erfolgreich!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Remove", :target => "Entfernen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create_if_not_exists( :locale => 'de', :source => "Add", :target => "Hinzufügen", :updated_by_id => 1, :created_by_id => 1  )

#Translation.create_if_not_exists( :locale => 'de', :source => "", :target => "", :updated_by_id => 1, :created_by_id => 1  )

# install all packages in auto_install
Package.auto_install()
