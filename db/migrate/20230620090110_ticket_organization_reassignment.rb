# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketOrganizationReassignment < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Organization Reassignment',
      name:        'ticket_organization_reassignment',
      area:        'Ticket::Base',
      description: 'Defines if the change of the primary organization of a user will update the 100 most recent tickets for this user as well.',
      options:     {
        form: [
          {
            display:   '',
            null:      false,
            name:      'ticket_organization_reassignment',
            tag:       'boolean',
            options:   {
              true  => 'Update the most recent tickets.',
              false => 'Do not update any tickets.',
            },
            translate: true,
          },
        ],
      },
      state:       true,
      preferences: {
        prio:       4000,
        permission: ['admin.ticket'],
      },
      frontend:    true
    )
  end
end
