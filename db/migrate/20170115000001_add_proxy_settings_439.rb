class AddProxySettings439 < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

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
            name: 'proxy_passowrd',
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

  end
end
