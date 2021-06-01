# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ApplicationSecretSetting < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Application secret',
      name:        'application_secret',
      area:        'Core',
      description: 'Defines the random application secret.',
      options:     {},
      state:       SecureRandom.hex(128),
      preferences: {
        permission: ['admin'],
      },
      frontend:    false
    )
  end
end
