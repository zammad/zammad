# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingProxy < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Proxy Settings',
      name:        'proxy',
      area:        'System::Network',
      description: 'Address of the proxy server for http and https resources.',
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
      title:       'Proxy User',
      name:        'proxy_username',
      area:        'System::Network',
      description: 'Username for proxy connection.',
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
    # fix typo
    setting = Setting.find_by(name: 'proxy_password')
    if setting
      setting.options[:form][0][:name] = 'proxy_password'
      setting.save!
    else
      Setting.create_if_not_exists(
        title:       'Proxy Password',
        name:        'proxy_password',
        area:        'System::Network',
        description: 'Password for proxy connection.',
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
    end
    Setting.create_if_not_exists(
      title:       'No Proxy',
      name:        'proxy_no',
      area:        'System::Network',
      description: 'No proxy for the following hosts.',
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
  end

end
