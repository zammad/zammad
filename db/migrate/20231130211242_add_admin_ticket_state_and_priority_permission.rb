# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class AddAdminTicketStateAndPriorityPermission < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.ticket_state',
      note:        'Manage %s Settings',
      preferences: {
        translations: ['Ticket States']
      },
    )
    Permission.create_if_not_exists(
      name:        'admin.ticket_priority',
      note:        'Manage %s Settings',
      preferences: {
        translations: ['Ticket Priorities']
      },
    )
  end
end
