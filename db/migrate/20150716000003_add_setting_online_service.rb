class AddSettingOnlineService < ActiveRecord::Migration
  def up

    Setting.create_or_update(
      title: 'System Init Done',
      name: 'system_init_done',
      area: 'Core',
      description: 'Defines if application is in init mode.',
      options: {},
      state: false,
      preferences: { online_service_disable: true },
      frontend: true
    )
    Setting.create_or_update(
      title: 'Developer System',
      name: 'developer_mode',
      area: 'Core::Develop',
      description: 'Defines if application is in developer mode (useful for developer, all users have the same password, password reset will work without email delivery).',
      options: {},
      state: false,
      preferences: { online_service_disable: true },
      frontend: true
    )
    Setting.create_or_update(
      title: 'Online Service',
      name: 'system_online_service',
      area: 'Core',
      description: 'Defines if application is used as online service.',
      options: {},
      state: false,
      preferences: { online_service_disable: true },
      frontend: true
    )
    Setting.create_or_update(
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
            options: {
              '10' => '10',
              '11' => '11',
              '12' => '12',
              '13' => '13',
            },
          },
        ],
      },
      state: '10',
      preferences: { online_service_disable: true },
      frontend: true
    )
    Setting.create_or_update(
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
    Setting.create_or_update(
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
    Setting.create_or_update(
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

    Setting.create_or_update(
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
    Setting.create_or_update(
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
      state: 10,
      preferences: { online_service_disable: true },
      frontend: false
    )
    Setting.create_or_update(
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

    Setting.create_or_update(
      title: 'Elasticsearch Endpoint URL',
      name: 'es_url',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define endpoint of Elastic Search.',
      state: '',
      preferences: { online_service_disable: true },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elasticsearch Endpoint User',
      name: 'es_user',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define http basic auth user of Elasticsearch.',
      state: '',
      preferences: { online_service_disable: true },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Endpoint Password',
      name: 'es_password',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define http basic auth password of Elasticsearch.',
      state: '',
      preferences: { online_service_disable: true },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Endpoint Index',
      name: 'es_index',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define Elasticsearch index name.',
      state: 'zammad',
      preferences: { online_service_disable: true },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Attachment Extentions',
      name: 'es_attachment_ignore',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define attachment extentions which are ignored for Elasticsearch.',
      state: [ '.png', '.jpg', '.jpeg', '.mpeg', '.mpg', '.mov', '.bin', '.exe', '.box', '.mbox' ],
      preferences: { online_service_disable: true },
      frontend: false
    )
    Setting.create_or_update(
      title: 'Elastic Search Attachment Size',
      name: 'es_attachment_max_size_in_mb',
      area: 'SearchIndex::Elasticsearch',
      description: 'Define max. attachment size for Elasticsearch.',
      state: 50,
      preferences: { online_service_disable: true },
      frontend: false
    )

  end

end
