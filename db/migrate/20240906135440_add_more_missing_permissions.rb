# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class AddMoreMissingPermissions < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.ticket_auto_assignment',
      label:       'Ticket Auto Assignment',
      description: 'Manage ticket auto assignment settings of your system.',
      preferences: { prio: 1331 }
    )

    Permission.create_if_not_exists(
      name:        'admin.ticket_duplicate_detection',
      label:       'Ticket Duplicate Detection',
      description: 'Manage ticket duplicate detection settings of your system.',
      preferences: { prio: 1332 }
    )
  end
end
