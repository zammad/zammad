# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddTicketParticipantsSettings < ActiveRecord::Migration[8.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Participants',
      name:        'ticket_participants_enabled',
      area:        'Ticket::Participants',
      description: 'Enable the participant feature. Allows adding additional customers as participants on tickets.',
      options:     {},
      state:       false,
      preferences: {
        permission: ['admin.ticket'],
      },
      frontend:    true,
    )
  end
end
