# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class MissingUiTicketCreateNotesSetting < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Additional notes for ticket create types.',
      name:        'ui_ticket_create_notes',
      area:        'UI::TicketCreate',
      description: 'Show additional notes for ticket creation depending on the selected type.',
      options:     {},
      state:       {},
      preferences: {
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
