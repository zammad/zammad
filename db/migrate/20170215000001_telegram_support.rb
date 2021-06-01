# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TelegramSupport < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.channel_telegram',
      note:        'Manage %s',
      preferences: {
        translations: ['Channel - Telegram']
      },
    )

    Ticket::Article::Type.create_if_not_exists(
      name:          'telegram personal-message',
      communication: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

  end
end
