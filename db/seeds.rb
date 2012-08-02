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
    :value => '50',
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
      :file     => '/tmp/counter.log',
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
      :file     => '/tmp/counter.log',
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
  :title       => 'System Sender',
  :name        => 'system_sender',
  :area        => 'Email::Base',
  :description => 'ONLY TEMP!',
  :options     => {
    :form => [
      {
        :display  => '',
        :null     => false,
        :name     => 'system_sender', 
        :tag      => 'input',
      },
    ],
  },
  :state => {
    :value => 'Zammad Team <zammad@#{config.fqdn}>',
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


Role.create(
  :id             => 1,
  :name           => 'Admin',
  :note           => 'To configure your system.',
  :created_by_id  => 1
)
Role.create(
  :id             => 2,
  :name           => 'Agent',
  :note           => 'To work on Tickets.',
  :created_by_id  => 1
)
Role.create(
  :id             => 3,
  :name           => 'Customer',
  :note           => 'People who create Tickets ask for help.',
  :created_by_id  => 1
)

Group.create(
  :id             => 1,
  :name           => 'Users',
  :note           => 'Standard Group/Pool for Tickets.',
  :created_by_id  => 1
)
Group.create(
  :id             => 2,
  :name           => 'Twitter',
  :note           => 'All Tweets.',
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
  :created_by_id => 1
)

Link::Type.create( :name => 'normal' )
Link::Object.create( :name => 'Ticket' )
Link::Object.create( :name => 'Announcement' )
Link::Object.create( :name => 'Question/Answer' )
Link::Object.create( :name => 'Idea' )
Link::Object.create( :name => 'Bug' )

Ticket::StateType.create( :name => 'new' )
Ticket::StateType.create( :name => 'open' )
Ticket::StateType.create( :name => 'pending reminder' )
Ticket::StateType.create( :name => 'pending action' )
Ticket::StateType.create( :name => 'closed' )
Ticket::StateType.create( :name => 'merged' )
Ticket::StateType.create( :name => 'removed' )

Ticket::State.create( :name => 'new', :ticket_state_type_id => Ticket::StateType.where(:name => 'new').first.id )
Ticket::State.create( :name => 'open', :ticket_state_type_id => Ticket::StateType.where(:name => 'open').first.id )
Ticket::State.create( :name => 'pending', :ticket_state_type_id => Ticket::StateType.where(:name => 'pending reminder').first.id  )
Ticket::State.create( :name => 'closed', :ticket_state_type_id  => Ticket::StateType.where(:name => 'closed').first.id  )
Ticket::State.create( :name => 'merged', :ticket_state_type_id  => Ticket::StateType.where(:name => 'merged').first.id  )
Ticket::State.create( :name => 'removed', :ticket_state_type_id  => Ticket::StateType.where(:name => 'removed').first.id  )

Ticket::Priority.create( :name => '1 low' )
Ticket::Priority.create( :name => '2 normal' )
Ticket::Priority.create( :name => '3 high' )

Ticket::Article::Type.create( :name => 'email', :communication => true )
Ticket::Article::Type.create( :name => 'sms', :communication => true )
Ticket::Article::Type.create( :name => 'chat', :communication => true )
Ticket::Article::Type.create( :name => 'fax', :communication => true )
Ticket::Article::Type.create( :name => 'phone', :communication => true )
Ticket::Article::Type.create( :name => 'twitter status', :communication => true )
Ticket::Article::Type.create( :name => 'twitter direct-message', :communication => true )
Ticket::Article::Type.create( :name => 'facebook', :communication => true )
Ticket::Article::Type.create( :name => 'note', :communication => false )

Ticket::Article::Sender.create( :name => 'Agent' )
Ticket::Article::Sender.create( :name => 'Customer' )
Ticket::Article::Sender.create( :name => 'System' )

ticket = Ticket.create(
  :group_id           => Group.where( :name => 'Users' ).first.id,
  :customer_id        => User.where( :login => 'nicole.braun@zammad.org' ).first.id,
  :owner_id           => User.where( :login => '-' ).first.id,
  :title              => 'Welcome to Zammad!',
  :ticket_state_id    => Ticket::State.where( :name => 'new' ).first.id,
  :ticket_priority_id => Ticket::Priority.where( :name => '2 normal' ).first.id,
  :created_by_id      => User.where( :login => 'nicole.braun@zammad.org' ).first.id
)
Ticket::Article.create(
  :created_by_id            => User.where( :login => 'nicole.braun@zammad.org' ).first.id,
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
  :internal                 => false
)

Overview.create(
  :name => 'my_assigned',
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
  }
)

Overview.create(
  :name => 'all_unassigned',
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
  }
)

Overview.create(
  :name => 'all_open',
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
  }
)

Overview.create(
  :name => 'all_escalated',
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
  }
)

Overview.create(
  :name => 'my_pending_reached',
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
  }
)

Overview.create(
  :name => 'all',
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
  }
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
  :created_by_id  => User.where( :login => '-' ).first.id
)
Channel.create(
  :adapter        => 'Sendmail',
  :area           => 'Email::Outbound',
  :options        => {},
  :active         => true,
  :created_by_id  => User.where( :login => '-' ).first.id
)

network = Network.create(
  :name   => 'base'
)

Network::Category::Type.create(
  :name   => 'Announcement'
)
Network::Category::Type.create(
  :name => 'Idea'
)
Network::Category::Type.create(
  :name => 'Question'
)
Network::Category::Type.create(
  :name => 'Bug Report'
)

Network::Privacy.create(
  :name => 'logged in',
  :key  => 'loggedIn'
)
Network::Privacy.create(
  :name => 'logged in and moderator',
  :key  => 'loggedInModerator'
)
Network::Category.create(
  :name                     => 'Announcements',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Announcement').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in and moderator').first.id,
  :allow_comments           => true
)
Network::Category.create(
  :name                     => 'Questions',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Question').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id
#  :network_categories_moderator_user_ids => User.where(:login => '-').first.id
)
Network::Category.create(
  :name                     => 'Ideas',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Idea').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
  :allow_comments           => true
)
Network::Category.create(
  :name                     => 'Bug Reports',
  :network_id               => network.id,
  :allow_comments           => true,
  :network_category_type_id => Network::Category::Type.where(:name => 'Bug Report').first.id,
  :network_privacy_id       => Network::Privacy.where(:name => 'logged in').first.id,
  :allow_comments           => true
)
item = Network::Item.create(
  :title                => 'Example Announcement',
  :body                 => 'Some announcement....',
  :network_category_id  => Network::Category.where(:name => 'Announcements').first.id,
  :created_by_id        => User.where(:login => '-').first.id
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :created_by_id    => User.where(:login => '-').first.id
)
item = Network::Item.create(
  :title                => 'Example Question?',
  :body                 => 'Some questions....',
  :network_category_id  => Network::Category.where(:name => 'Questions').first.id,
  :created_by_id        => User.where(:login => '-').first.id
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :created_by_id    => User.where(:login => '-').first.id
)
item = Network::Item.create(
  :title                => 'Example Idea',
  :body                 => 'Some idea....',
  :network_category_id  => Network::Category.where(:name => 'Ideas').first.id,
  :created_by_id        => User.where(:login => '-').first.id
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :created_by_id    => User.where(:login => '-').first.id
)
item = Network::Item.create(
  :title                => 'Example Bug Report',
  :body                 => 'Some bug....',
  :network_category_id  => Network::Category.where(:name => 'Bug Reports').first.id,
  :created_by_id        => User.where(:login => '-').first.id
)
Network::Item::Comment.create(
  :network_item_id  => item.id,
  :body             => 'Some comment....',
  :created_by_id    => User.where(:login => '-').first.id
)

Translation.create( :locale => 'de', :source => "New", :target => "Neu" )
Translation.create( :locale => 'de', :source => "Create", :target => "Erstellen" )
Translation.create( :locale => 'de', :source => "Cancel", :target => "Abbrechen" )
Translation.create( :locale => 'de', :source => "Submit", :target => "Übermitteln" )
Translation.create( :locale => 'de', :source => "Sign out", :target => "Abmelden" )
Translation.create( :locale => 'de', :source => "Profile", :target => "Profil" )
Translation.create( :locale => 'de', :source => "Settings", :target => "Einstellungen" )
Translation.create( :locale => 'de', :source => "Overviews", :target => "Übersichten" )
Translation.create( :locale => 'de', :source => "Manage", :target => "Verwalten" )
Translation.create( :locale => 'de', :source => "Users", :target => "Benutzer" )
Translation.create( :locale => 'de', :source => "Groups", :target => "Gruppen" )
Translation.create( :locale => 'de', :source => "Group", :target => "Gruppe" )
Translation.create( :locale => 'de', :source => "Organizations", :target => "Organisationen" )
Translation.create( :locale => 'de', :source => "Organization", :target => "Organisation" )
Translation.create( :locale => 'de', :source => "Recent Viewed", :target => "Zuletzt angesehen" )
Translation.create( :locale => 'de', :source => "Security", :target => "Sicherheit" )
Translation.create( :locale => 'de', :source => "From", :target => "Von" )
Translation.create( :locale => 'de', :source => "Title", :target => "Titel" )
Translation.create( :locale => 'de', :source => "Customer", :target => "Kunde" )
Translation.create( :locale => 'de', :source => "State", :target => "Status" )
Translation.create( :locale => 'de', :source => "Created", :target => "Erstellt" )
Translation.create( :locale => 'de', :source => "Attributes", :target => "Attribute" )
Translation.create( :locale => 'de', :source => "Direction", :target => "Richtung" )
Translation.create( :locale => 'de', :source => "Owner", :target => "Besitzer" )
Translation.create( :locale => 'de', :source => "Subject", :target => "Betreff" )
Translation.create( :locale => 'de', :source => "Priority", :target => "Priorität" )
Translation.create( :locale => 'de', :source => "Select the customer of the Ticket or create one.", :target => "Wähle den Kunden eine Tickets oder erstell einen neuen." )
Translation.create( :locale => 'de', :source => "New Ticket", :target => "Neues Ticket" )
Translation.create( :locale => 'de', :source => "Firstname", :target => "Vorname" )
Translation.create( :locale => 'de', :source => "Lastname", :target => "Nachname" )
Translation.create( :locale => 'de', :source => "Phone", :target => "Telefon" )
Translation.create( :locale => 'de', :source => "Street", :target => "Straße" )
Translation.create( :locale => 'de', :source => "Zip", :target => "PLZ" )
Translation.create( :locale => 'de', :source => "City", :target => "Stadt" )
Translation.create( :locale => 'de', :source => "Note", :target => "Notiz" )
Translation.create( :locale => 'de', :source => "note", :target => "Notiz" )
Translation.create( :locale => 'de', :source => "New User", :target => "Neuer Benutzer" )
Translation.create( :locale => 'de', :source => "Merge", :target => "Zusammenfügen" )
Translation.create( :locale => 'de', :source => "History", :target => "Historie" )
Translation.create( :locale => 'de', :source => "new", :target => "neu" )
Translation.create( :locale => 'de', :source => "closed", :target => "geschlossen" )
Translation.create( :locale => 'de', :source => "open", :target => "offen" )
Translation.create( :locale => 'de', :source => "pending", :target => "warten" )
Translation.create( :locale => 'de', :source => "merged", :target => "zusammengefügt" )
Translation.create( :locale => 'de', :source => "removed", :target => "zurück gezogen" )
Translation.create( :locale => 'de', :source => "Activity Stream", :target => "Aktivitäts-Stream" )
Translation.create( :locale => 'de', :source => "updated", :target => "aktuallisierte" )
Translation.create( :locale => 'de', :source => "created", :target => "erstellte" )
Translation.create( :locale => 'de', :source => "My assigned Tickets", :target => "Meine zugewisenen Tickets" )
Translation.create( :locale => 'de', :source => "Unassigned Tickets", :target => "Nicht zugewisene/freie Tickets" )
Translation.create( :locale => 'de', :source => "Unassigned & Open Tickets", :target => "Nicht zugewisene & offene Tickets" )
Translation.create( :locale => 'de', :source => "All Tickets", :target => "Alle Tickets" )
Translation.create( :locale => 'de', :source => "Escalated Tickets", :target => "Eskallierte Tickets" )
Translation.create( :locale => 'de', :source => "My pending reached Tickets", :target => "Meine warten erreicht Tickets" )
Translation.create( :locale => 'de', :source => "Password", :target => "Passwort" )
Translation.create( :locale => 'de', :source => "Password (confirm)", :target => "Passwort (bestätigen)" )
Translation.create( :locale => 'de', :source => "Roles", :target => "Rollen" )
Translation.create( :locale => 'de', :source => "Active", :target => "Aktiv" )
Translation.create( :locale => 'de', :source => "Edit", :target => "Bearbeiten" )
Translation.create( :locale => 'de', :source => "Base", :target => "Basis" )
Translation.create( :locale => 'de', :source => "Number", :target => "Nummer" )
Translation.create( :locale => 'de', :source => "Sender Format", :target => "Absender Format" )
Translation.create( :locale => 'de', :source => "Authentication", :target => "Authorisierung" )
Translation.create( :locale => 'de', :source => "Product Name", :target => "Produkt Name" )
Translation.create( :locale => 'de', :source => "To", :target => "An" )
Translation.create( :locale => 'de', :source => "Customer", :target => "Kunde" )
Translation.create( :locale => 'de', :source => "Linked Accounts", :target => "Verknüpfte Accounts" )
Translation.create( :locale => 'de', :source => "Sign in with", :target => "Anmelden mit" )
Translation.create( :locale => 'de', :source => "Username or email", :target => "Benutzer oder Email" )
Translation.create( :locale => 'de', :source => "Remember me", :target => "An mich erinnern" )
Translation.create( :locale => 'de', :source => "Forgot password?", :target => "Passwort vergessen?" )
Translation.create( :locale => 'de', :source => "Sign in using", :target => "Anmelden über" )
Translation.create( :locale => 'de', :source => "New to", :target => "Neu bei" )
Translation.create( :locale => 'de', :source => "join today!", :target => "werde Teil!" )
Translation.create( :locale => 'de', :source => "Sign up", :target => "Registrieren" )
Translation.create( :locale => 'de', :source => "Sign in", :target => "Anmelden" )
Translation.create( :locale => 'de', :source => "Create my account", :target => "Meinen Account erstellen" )
Translation.create( :locale => 'de', :source => "Login successfully! Have a nice day!", :target => "Anmeldung erfolgreich!" )
Translation.create( :locale => 'de', :source => "Last contact", :target => "Letzter Kontakt" )
Translation.create( :locale => 'de', :source => "Last contact (Agent)", :target => "Letzter Kontakt (Agent)" )
Translation.create( :locale => 'de', :source => "Last contact (Customer)", :target => "Letzter Kontakt (Kunde)" )
Translation.create( :locale => 'de', :source => "Close time", :target => "Schließzeit" )
Translation.create( :locale => 'de', :source => "First response", :target => "Erste Reaktion" )
Translation.create( :locale => 'de', :source => "Ticket %s created!", :target => "Ticket %s erstellt!" )
Translation.create( :locale => 'de', :source => "day", :target => "Tag" )
Translation.create( :locale => 'de', :source => "days", :target => "Tage" )
Translation.create( :locale => 'de', :source => "hour", :target => "Stunde" )
Translation.create( :locale => 'de', :source => "hours", :target => "Stunden" )
Translation.create( :locale => 'de', :source => "minute", :target => "Minute" )
Translation.create( :locale => 'de', :source => "minutes", :target => "Minuten" )
Translation.create( :locale => 'de', :source => "See more", :target => "mehr anzeigen" )
Translation.create( :locale => 'de', :source => "Search", :target => "Suche" )
Translation.create( :locale => 'de', :source => "Forgot your password?", :target => "Passwort vergessen?" )
Translation.create( :locale => 'de', :source => "Templates", :target => "Vorlagen" )
Translation.create( :locale => 'de', :source => "Delete", :target => "Löschen" )
Translation.create( :locale => 'de', :source => "Apply", :target => "Übernehmen" )
Translation.create( :locale => 'de', :source => "Save as Template", :target => "Als Template speichern" )
Translation.create( :locale => 'de', :source => "Save", :target => "Speichern" )
Translation.create( :locale => 'de', :source => "Open Tickets", :target => "Offene Ticket" )
Translation.create( :locale => 'de', :source => "Closed Tickets", :target => "Geschlossene Ticket" )
Translation.create( :locale => 'de', :source => "set to internal", :target => "auf intern setzen" )
Translation.create( :locale => 'de', :source => "set to public", :target => "auf öffentlich setzen" )
Translation.create( :locale => 'de', :source => "split", :target => "teilen" )
Translation.create( :locale => 'de', :source => "Type", :target => "Typ" )
Translation.create( :locale => 'de', :source => "raw", :target => "unverarbeitet" )
Translation.create( :locale => 'de', :source => "1 low", :target => "1 niedrig" )
Translation.create( :locale => 'de', :source => "2 normal", :target => "2 normal" )
Translation.create( :locale => 'de', :source => "3 high", :target => "3 hoch" )
Translation.create( :locale => 'de', :source => "public", :target => "öffentlich" )
Translation.create( :locale => 'de', :source => "internal", :target => "intern" )
Translation.create( :locale => 'de', :source => "Attach files", :target => "Dateien anhängen" )
Translation.create( :locale => 'de', :source => "Visability", :target => "Sichtbarkeit" )
Translation.create( :locale => 'de', :source => "Actions", :target => "Aktionen" )
Translation.create( :locale => 'de', :source => "email", :target => "E-Mail" )
Translation.create( :locale => 'de', :source => "phone", :target => "Telefon" )
Translation.create( :locale => 'de', :source => "fax", :target => "Fax" )
Translation.create( :locale => 'de', :source => "chat", :target => "Chat" )
Translation.create( :locale => 'de', :source => "sms", :target => "SMS" )
Translation.create( :locale => 'de', :source => "twitter status", :target => "Twitter Status Meldung" )
Translation.create( :locale => 'de', :source => "twitter direct-message", :target => "Twitter Direkt-Nachricht" )
Translation.create( :locale => 'de', :source => "All Open Tickets", :target => "Alle offenen Tickets" )
#Translation.create( :locale => 'de', :source => "", :target => "" )
