# encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)
Setting.create(
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
  :state => {
    :value => 'Zammad',
  },
  :frontend => true
)

Setting.create(
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
  :state => {
    :value => 'Example Inc.',
  },
  :frontend => true
)

Setting.create(
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
  :state => {
    :value => '10',
  },
  :frontend => true
)
Setting.create(
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
  :state => {
    :value => 'zammad.example.com',
  },
  :frontend => true
)
Setting.create(
  :title       => 'http type',
  :name        => 'http_type',
  :area        => 'System::Base',
  :description => 'Defines the type of protocol, used by ther web server, to serve the application. If https protocol will be used instead of plain http, it must be specified it here. Since this has no affect on the web server\'s settings or behavior, it will not change the method of access to the application and, if it is wrong, it will not prevent you from logging into the application. This setting is used as a variable, #{setting.http_type} which is found in all forms of messaging used by the application, to build links to the tickets within your system.',
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
  :state       => {
    :value => 'http',
  },
  :frontend    => true
)



Setting.create(
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
  :state       => {
    :value => 'DB',
  },
  :frontend    => false
)


Setting.create(
  :title       => 'New User Accouts',
  :name        => 'user_create_account',
  :area        => 'Security::Authentication',
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
  :state       => {
    :value => true,
  },
  :frontend    => true
)
Setting.create(
  :title       => 'Lost Password',
  :name        => 'user_lost_password',
  :area        => 'Security::Authentication',
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
  :state       => {
    :value => true,
  },
  :frontend    => true
)
Setting.create(
  :title       => 'Switch to User',
  :name        => 'switch_to_user',
  :area        => 'Security::Authentication',
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
  :state => {
    :value => false,
  },
  :frontend => true
)
Setting.create(
  :title       => 'Autentication via Database',
  :name        => 'auth_db',
  :area        => 'Security::Authentication',
  :description => 'Enables user authentication via database.',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => true,
        :name     => 'auth_db', 
        :tag      => 'boolean',
        :options  => {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  :state => {
    :value => true,
  },
  :frontend => true
)
Setting.create(
  :title       => 'Autentication via Twitter',
  :name        => 'auth_twitter',
  :area        => 'Security::Authentication',
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
  :state => {
    :value => false,
  },
  :frontend => true
)
Setting.create(
  :title       => 'Twitter App Credentials',
  :name        => 'auth_twitter_credentials',
  :area        => 'Security::Authentication',
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
  :state => {
    :value => {}
  },
  :frontend => false
)
Setting.create(
  :title       => 'Autentication via Facebook',
  :name        => 'auth_facebook',
  :area        => 'Security::Authentication',
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
  :state       => {
    :value => false,
  },
  :frontend => true
)

Setting.create(
  :title       => 'Facebook App Credentials',
  :name        => 'auth_facebook_credentials',
  :area        => 'Security::Authentication',
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
  :state => {
    :value => {},
  },
  :frontend => false
)

Setting.create(
  :title       => 'Autentication via Google',
  :name        => 'auth_google_oauth2',
  :area        => 'Security::Authentication',
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
  :state       => {
    :value => false,
  },
  :frontend    => true
)
Setting.create(
  :title       => 'Google App Credentials',
  :name        => 'auth_google_oauth2_credentials',
  :area        => 'Security::Authentication',
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
  :state => {
    :value => {},
  },
  :frontend => false
)

Setting.create(
  :title       => 'Autentication via LinkedIn',
  :name        => 'auth_linkedin',
  :area        => 'Security::Authentication',
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
  :state       => {
    :value => false,
  },
  :frontend    => true
)
Setting.create(
  :title       => 'LinkedIn App Credentials',
  :name        => 'auth_linkedin_credentials',
  :area        => 'Security::Authentication',
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
  :state => {
    :value => {},
  },
  :frontend => false
)

Setting.create(
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
  :state       => {
    :value => 6,
  },
  :frontend    => true
)
Setting.create(
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
  :state       => {
    :value => 0,
  },
  :frontend    => true
)
Setting.create(
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
  :state       => {
    :value => 0,
  },
  :frontend    => true
)
Setting.create(
  :title       => 'Maximal failed logins',
  :name        => 'password_max_login_failed',
  :area        => 'Security::Password',
  :description => 'Maximal faild logins after account is inactive.',
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
          12 => 12,
        },
      },
    ],
  },
  :state       => {
    :value => 6,
  },
  :frontend    => true
)

Setting.create(
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
  :state       => {
    :value => 'Ticket#',
  },
  :frontend    => true
)
Setting.create(
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
  :state       => {
    :value => '',
  },
  :frontend    => false
)
Setting.create(
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
  :state       => {
    :value => 'right',
  },
  :frontend    => false
)
Setting.create(
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
  :state       => {
    :value => '110',
  },
  :frontend    => false
)
Setting.create(
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
  :state       => {
    :value => 'RE',
  },
  :frontend    => false
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

Setting.create(
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
  :state => {
    :value => 'increment',
  },
  :frontend => false
)
Setting.create(
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
      {
        :display  => 'Logfile',
        :null     => false,
        :name     => 'file', 
        :tag      => 'input',
      },
    ],
  },
  :state => {
    :value => {
      :checksum => false,
      :file     => 'tmp/counter.log',
      :min_size => 5,
    },
  },
  :frontend => false
)
Setting.create(
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
      {
        :display  => 'Logfile',
        :null     => false,
        :name     => 'file', 
        :tag      => 'input',
      },
    ],
  },
  :state => {
    :value => {
      :checksum => false,
      :file     => 'tmp/counter.log',
    }
  },
  :frontend => false
)

Setting.create(
  :title       => 'Sender Format',
  :name        => 'ticket_define_email_from',
  :area        => 'Ticket::SenderFormat',
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
  :state => {
    :value => 'SystemAddressName',
  },
  :frontend => false
)

Setting.create(
  :title       => 'Sender Format Seperator',
  :name        => 'ticket_define_email_from_seperator',
  :area        => 'Ticket::SenderFormat',
  :description => 'Defines the separator between the agents real name and the given queue email address.',
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
  :state => {
    :value => 'via',
  },
  :frontend => false
)

Setting.create(
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
  :state => {
    :value => true,
  },
  :frontend => true
)

Setting.create(
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
  :state       => {
    :value => true,
  },
  :frontend    => true
)

Setting.create(
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
  :state => {
    :value => 10,
  },
  :frontend => false
)

Setting.create(
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
  :state => {
    :value => ['subject'],
  },
  :frontend => false
)

Setting.create(
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
  :state => {
    :value => 'Notification Master <noreply@#{config.fqdn}>',
  },
  :frontend => false
)

Setting.create(
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
  :state => {
    :value => '(MAILER-DAEMON|postmaster|abuse)@.+?\..+?',
  },
  :frontend => false
)

Setting.create(
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
  :state => {
    :value => false,
  },
  :frontend => true
)

email_address = EmailAddress.create(
  :id             => 1,
  :realname       => 'Zammad',
  :email          => 'zammad@localhost',
  :updated_by_id  => 1,
  :created_by_id  => 1
)
signature = Signature.create(
  :name => 'default',
  :body => '
  #{user.firstname} #{user.lastname}

--
 Super Support - Waterford Business Park
 5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
 Email: hot@example.com - Web: http://www.example.com/
--
)',
  :updated_by_id  => 1,
  :created_by_id  => 1
)

Role.create(
  :id             => 1,
  :name           => 'Admin',
  :note           => 'To configure your system.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)
Role.create(
  :id             => 2,
  :name           => 'Agent',
  :note           => 'To work on Tickets.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)
Role.create(
  :id             => 3,
  :name           => 'Customer',
  :note           => 'People who create Tickets ask for help.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)

Group.create(
  :id               => 1,
  :name             => 'Users',
  :email_address_id => email_address.id,
  :signature_id     => signature.id,
  :note             => 'Standard Group/Pool for Tickets.',
  :updated_by_id    => 1,
  :created_by_id    => 1
)
Group.create(
  :id             => 2,
  :name           => 'Twitter',
  :note           => 'All Tweets.',
  :updated_by_id  => 1,
  :created_by_id  => 1
)

roles         = Role.where( :name => 'Customer' )
organizations = Organization.find( :all )
groups        = Group.find( :all )

user = User.create(
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
user_community = User.create(
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

Link::Type.create( :name => 'normal' )
Link::Object.create( :name => 'Ticket' )
Link::Object.create( :name => 'Announcement' )
Link::Object.create( :name => 'Question/Answer' )
Link::Object.create( :name => 'Idea' )
Link::Object.create( :name => 'Bug' )

Ticket::StateType.create( :name => 'new', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create( :name => 'open', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create( :name => 'pending reminder', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create( :name => 'pending action', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create( :name => 'closed', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create( :name => 'merged', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::StateType.create( :name => 'removed', :updated_by_id  => 1, :created_by_id => 1 )

Ticket::State.create( :name => 'new', :ticket_state_type_id => Ticket::StateType.where(:name => 'new').first.id, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::State.create( :name => 'open', :ticket_state_type_id => Ticket::StateType.where(:name => 'open').first.id, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::State.create( :name => 'pending', :ticket_state_type_id => Ticket::StateType.where(:name => 'pending reminder').first.id, :updated_by_id  => 1, :created_by_id => 1  )
Ticket::State.create( :name => 'closed', :ticket_state_type_id  => Ticket::StateType.where(:name => 'closed').first.id, :updated_by_id  => 1, :created_by_id => 1  )
Ticket::State.create( :name => 'merged', :ticket_state_type_id  => Ticket::StateType.where(:name => 'merged').first.id, :updated_by_id  => 1, :created_by_id => 1  )
Ticket::State.create( :name => 'removed', :ticket_state_type_id  => Ticket::StateType.where(:name => 'removed').first.id, :updated_by_id  => 1, :created_by_id => 1  )

Ticket::Priority.create( :name => '1 low', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Priority.create( :name => '2 normal', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Priority.create( :name => '3 high', :updated_by_id  => 1, :created_by_id => 1 )

Ticket::Article::Type.create( :name => 'email', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'sms', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'chat', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'fax', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'phone', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'twitter status', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'twitter direct-message', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'facebook', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'note', :communication => false, :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Type.create( :name => 'web', :communication => true, :updated_by_id  => 1, :created_by_id => 1 )

Ticket::Article::Sender.create( :name => 'Agent', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Sender.create( :name => 'Customer', :updated_by_id  => 1, :created_by_id => 1 )
Ticket::Article::Sender.create( :name => 'System', :updated_by_id  => 1, :created_by_id => 1 )

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
Overview.create(
  :name      => 'my_assigned',
  :role_id   => overview_role.id,
  :condition => {
    :ticket_state_id => [ 1,2,3 ],
    :owner_id        => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :meta => {
    :url  => 'my_assigned',
    :name => 'My assigned Tickets',
    :prio => 1000,
  },
  :view => {
    :d => {
      :overview => [
        'title', 'customer', 'ticket_state', 'group', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create(
  :name      => 'all_unassigned',
  :role_id   => overview_role.id,
  :condition => {
    :ticket_state_id => [1,2,3],
    :owner_id        => 1,
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :meta => {
    :url  => 'all_unassigned',
    :name => 'Unassigned & Open Tickets',
    :prio => 1001,
  },
  :view => {
    :d => {
      :overview => [
        'title', 'customer', 'ticket_state', 'group', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create(
  :name      => 'all_open',
  :role_id   => overview_role.id,
  :condition => {
    :ticket_state_id => [1,2,3],
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :meta => {
    :url  => 'all_open',
    :name => 'All Open Tickets',
    :prio => 1002,
  },
  :view => {
    :d => {
      :overview => [
        'title', 'customer', 'ticket_state', 'group', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create(
  :name      => 'all_escalated',
  :role_id   => overview_role.id,
  :condition => {
    :ticket_state_id => [1,2,3],
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :meta => {
    :url  => 'all_escalated',
    :name => 'Escalated Tickets',
    :prio => 1010,
  },
  :view => {
    :d => {
      :overview => [
        'title', 'customer', 'ticket_state', 'group', 'owner', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'owner', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'owner', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create(
  :name      => 'my_pending_reached',
  :role_id   => overview_role.id,
  :condition => {
    :ticket_state_id => [3],
    :owner_id        => 'current_user.id',        
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :meta => {
    :url  => 'my_pending_reached',
    :name => 'My pending reached Tickets',
    :prio => 1020,
  },
  :view => {
    :d => {
      :overview => [
        'title', 'customer', 'ticket_state', 'group', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Overview.create(
  :name      => 'all',
  :role_id   => overview_role.id,
  :condition => {
#          :ticket_state_id => [3],
#          :owner_id        => current_user.id,        
  },
  :order => {
    :by        => 'created_at',
    :direction => 'ASC',
  },
  :meta => {
    :url  => 'all',
    :name => 'All Tickets',
    :prio => 9003,
  },
  :view => {
    :s => {
      :overview => [
        'title', 'customer', 'ticket_state', 'group', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'group', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

overview_role = Role.where( :name => 'Customer' ).first
Overview.create(
  :name      => 'my_tickets',
  :role_id   => overview_role.id,
  :condition => {
    :customer_id => 'current_user.id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :meta => {
    :url  => 'my_tickets',
    :name => 'My Tickets',
    :prio => 1000,
  },
  :view => {
    :d => {
      :overview => [
        'title', 'customer', 'ticket_state', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'ticket_state', 'ticket_priority', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'ticket_state', 'ticket_priority', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)
Overview.create(
  :name                => 'my_organization_tickets',
  :role_id             => overview_role.id,
  :organization_shared => true,
  :condition => {
    :organization_id => 'current_user.organization_id',
  },
  :order => {
    :by        => 'created_at',
    :direction => 'DESC',
  },
  :meta => {
    :url  => 'my_organization_tickets',
    :name => 'My Organization Tickets',
    :prio => 1100,
  },
  :view => {
    :d => {
      :overview => [
        'title', 'customer', 'ticket_state', 'created_at'
      ],
      :per_page => 5,
    },
    :s => {
      :overview => [
        'number', 'title', 'customer', 'ticket_state', 'ticket_priority', 'created_at'
      ],
      :per_page => 30,
    },
    :m => {
      :overview => [
        'number', 'title', 'ticket_state', 'ticket_priority', 'created_at'
      ],
      :per_page => 20,
    },
    :view_mode_default => 's',
  },
  :updated_by_id => 1,
  :created_by_id => 1
)

Channel.create(
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
Channel.create(
  :adapter        => 'Sendmail',
  :area           => 'Email::Outbound',
  :options        => {},
  :active         => true,
  :updated_by_id  => 1,
  :created_by_id  => 1,
)

network = Network.create(
  :name   => 'base',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)

Network::Category::Type.create(
  :name   => 'Announcement',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category::Type.create(
  :name => 'Idea',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category::Type.create(
  :name => 'Question',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category::Type.create(
  :name => 'Bug Report',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)

Network::Privacy.create(
  :name => 'logged in',
  :key  => 'loggedIn',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Privacy.create(
  :name => 'logged in and moderator',
  :key  => 'loggedInModerator',
  :updated_by_id  => 1,
  :created_by_id  => 1,
)
Network::Category.create(
  :name                     => 'Announcements',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Announcement').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in and moderator').first.id,
  :allow_comments           => true,
  :updated_by_id            => 1,
  :created_by_id            => 1,
)
Network::Category.create(
  :name                     => 'Questions',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Question').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
#  :network_categories_moderator_user_ids => User.where(:login => '-').first.id,
  :updated_by_id            => 1,
  :created_by_id            => 1,
)
Network::Category.create(
  :name                     => 'Ideas',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Idea').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
  :allow_comments           => true,
  :updated_by_id            => 1,
  :created_by_id            => 1,
)
Network::Category.create(
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

Translation.create( :locale => 'de', :source => "New", :target => "Neu", :updated_by_id => 1, :created_by_id => 1 )
Translation.create( :locale => 'de', :source => "Create", :target => "Erstellen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Cancel", :target => "Abbrechen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Submit", :target => "Übermitteln", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Sign out", :target => "Abmelden", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Profile", :target => "Profil", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Settings", :target => "Einstellungen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Overviews", :target => "Übersichten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Manage", :target => "Verwalten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Users", :target => "Benutzer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Groups", :target => "Gruppen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Group", :target => "Gruppe", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Organizations", :target => "Organisationen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Organization", :target => "Organisation", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Recent Viewed", :target => "Zuletzt angesehen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Security", :target => "Sicherheit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "From", :target => "Von", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Title", :target => "Titel", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Customer", :target => "Kunde", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "State", :target => "Status", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Created", :target => "Erstellt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Attributes", :target => "Attribute", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Direction", :target => "Richtung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Owner", :target => "Besitzer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Subject", :target => "Betreff", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Priority", :target => "Priorität", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Select the customer of the Ticket or create one.", :target => "Wähle den Kunden eine Tickets oder erstell einen neuen.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "New Ticket", :target => "Neues Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Firstname", :target => "Vorname", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Lastname", :target => "Nachname", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Phone", :target => "Telefon", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Street", :target => "Straße", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Zip", :target => "PLZ", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "City", :target => "Stadt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Note", :target => "Notiz", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "note", :target => "Notiz", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "New User", :target => "Neuer Benutzer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Merge", :target => "Zusammenfügen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "History", :target => "Historie", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "new", :target => "neu", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "closed", :target => "geschlossen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "open", :target => "offen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "pending", :target => "warten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "merged", :target => "zusammengefügt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "removed", :target => "zurück gezogen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Activity Stream", :target => "Aktivitäts-Stream", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "updated", :target => "aktuallisierte", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "created", :target => "erstellte", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "My assigned Tickets", :target => "Meine zugewisenen Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Unassigned Tickets", :target => "Nicht zugewisene/freie Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Unassigned & Open Tickets", :target => "Nicht zugewisene & offene Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "All Tickets", :target => "Alle Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Escalated Tickets", :target => "Eskallierte Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "My pending reached Tickets", :target => "Meine warten erreicht Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Password", :target => "Passwort", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Password (confirm)", :target => "Passwort (bestätigen)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Roles", :target => "Rollen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Active", :target => "Aktiv", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Edit", :target => "Bearbeiten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Base", :target => "Basis", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Number", :target => "Nummer", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Sender Format", :target => "Absender Format", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Authentication", :target => "Authorisierung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Product Name", :target => "Produkt Name", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "To", :target => "An", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Customer", :target => "Kunde", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Linked Accounts", :target => "Verknüpfte Accounts", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Sign in with", :target => "Anmelden mit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Username or email", :target => "Benutzer oder Email", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Remember me", :target => "An mich erinnern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Forgot password?", :target => "Passwort vergessen?", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Sign in using", :target => "Anmelden über", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "New to", :target => "Neu bei", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "join today!", :target => "werde Teil!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Sign up", :target => "Registrieren", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Sign in", :target => "Anmelden", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Create my account", :target => "Meinen Account erstellen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Login successfully! Have a nice day!", :target => "Anmeldung erfolgreich!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Last contact", :target => "Letzter Kontakt", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Last contact (Agent)", :target => "Letzter Kontakt (Agent)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Last contact (Customer)", :target => "Letzter Kontakt (Kunde)", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Close time", :target => "Schließzeit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "First response", :target => "Erste Reaktion", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Ticket %s created!", :target => "Ticket %s erstellt!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "day", :target => "Tag", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "days", :target => "Tage", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "hour", :target => "Stunde", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "hours", :target => "Stunden", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "minute", :target => "Minute", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "minutes", :target => "Minuten", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "See more", :target => "mehr anzeigen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Search", :target => "Suche", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Forgot your password?", :target => "Passwort vergessen?", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Templates", :target => "Vorlagen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Delete", :target => "Löschen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Apply", :target => "Übernehmen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Save as Template", :target => "Als Template speichern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Save", :target => "Speichern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Open Tickets", :target => "Offene Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Closed Tickets", :target => "Geschlossene Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "set to internal", :target => "auf intern setzen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "set to public", :target => "auf öffentlich setzen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "split", :target => "teilen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Type", :target => "Typ", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "raw", :target => "unverarbeitet", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "1 low", :target => "1 niedrig", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "2 normal", :target => "2 normal", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "3 high", :target => "3 hoch", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "public", :target => "öffentlich", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "internal", :target => "intern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Attach files", :target => "Dateien anhängen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Visability", :target => "Sichtbarkeit", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Actions", :target => "Aktionen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "email", :target => "E-Mail", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "phone", :target => "Telefon", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "fax", :target => "Fax", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "chat", :target => "Chat", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "sms", :target => "SMS", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "twitter status", :target => "Twitter Status Meldung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "twitter direct-message", :target => "Twitter Direkt-Nachricht", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "All Open Tickets", :target => "Alle offenen Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "child", :target => "Kind", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "parent", :target => "Eltern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "normal", :target => "Normal", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Linked Objects", :target => "Verknüpfte Objekte", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Links", :target => "Verknüpftungen", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Change Customer", :target => "Kunden ändern", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "My Tickets", :target => "Meine Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "My Organization Tickets", :target => "Meine Organisations Tickets", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "My Organization", :target => "Meine Organisation", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Assignment Timout", :target => "Zeitliche Zuweisungsüberschritung", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "We've sent password reset instructions to your email address.", :target => "Wir haben Ihnen die Anleitung zum zurücksetzen Ihres Passworts an Ihre E-Mail-Adresse gesendet.", :updated_by_id => 1, :created_by_id => 1 )
Translation.create( :locale => 'de', :source => "Enter your username or email address", :target => "Bitte geben Sie Ihren Benutzernamen oder E-Mail-Adresse ein", :updated_by_id => 1, :created_by_id => 1 )
Translation.create( :locale => 'de', :source => "Choose your new password.", :target => "Wählen Sie Ihr neues Passwort.", :updated_by_id => 1, :created_by_id => 1 )
Translation.create( :locale => 'de', :source => "Woo hoo! Your password has been changed!", :target => "Vielen Dank, Ihr Passwort wurde geändert!", :updated_by_id => 1, :created_by_id => 1 )
Translation.create( :locale => 'de', :source => "Please try to login!", :target => "Bitte melden Sie sich nun an!", :updated_by_id => 1, :created_by_id => 1 )
Translation.create( :locale => 'de', :source => "Username or email address invalid, please try again.", :target => "Benutzername oder E-Mail-Addresse ungültig, bitte erneut versuchen.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "If you don\'t receive instructions within a minute or two, check your email\'s spam and junk filters, or try resending your request.", :target => "Wir haben die Anforderung per E-Mail an Sie versendet, bitte überprüfen Sie Ihr Email-Postfach (auch die Junk E-Mails) ggf. starten Sie eine Anforderung erneut.", :updated_by_id => 1, :created_by_id => 1 )
Translation.create( :locale => 'de', :source => "again", :target => "erneut", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "none", :target => "keine", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Welcome!", :target => "Willkommen!", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Please click the button below to create your first one.", :target => "Klicken Sie die Schaltfläche unten um das erste zu erstellen.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "Create your first Ticket", :target => "Erstellen Sie Ihr erstes Ticket", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "You have not created a Ticket yet.", :target => "Sie haben noch kein Ticket erstellt.", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "The way to communicate with us is this thing called \"Ticket\".", :target => "Der Weg um mit uns zu kommunizieren ist das sogenannte \"Ticket\".", :updated_by_id => 1, :created_by_id => 1  )
Translation.create( :locale => 'de', :source => "or", :target => "oder", :updated_by_id => 1, :created_by_id => 1  )


#Translation.create( :locale => 'de', :source => "", :target => "", :updated_by_id => 1, :created_by_id => 1  )
