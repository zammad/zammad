# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingAddSipgateAlternativeFqdn < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'sipgate.io alternative fqdn',
      name:        'sipgate_alternative_fqdn',
      area:        'Integration::Sipgate::Expert',
      description: 'Alternative FQDN for callbacks if you operate Zammad in internal network.',
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
  end

end
