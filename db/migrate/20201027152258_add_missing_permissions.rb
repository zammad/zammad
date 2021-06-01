# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AddMissingPermissions < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.channel_google',
      note:        'Manage %s',
      preferences: {
        translations: ['Channel - Google']
      },
    )

    Permission.create_if_not_exists(
      name:        'admin.channel_microsoft365',
      note:        'Manage %s',
      preferences: {
        translations: ['Channel - Microsoft 365']
      },
    )
  end
end
