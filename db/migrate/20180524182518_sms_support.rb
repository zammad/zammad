# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SmsSupport < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.channel_sms',
      note:        'Manage %s',
      preferences: {
        translations: ['Channel - SMS']
      },
    )
  end
end
