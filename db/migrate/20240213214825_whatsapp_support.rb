# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class WhatsappSupport < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.channel_whatsapp',
      note:        'Manage %s',
      preferences: {
        translations: ['Channel - WhatsApp']
      },
    )

    Ticket::Article::Type.create_if_not_exists(
      name:          'whatsapp message',
      communication: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
