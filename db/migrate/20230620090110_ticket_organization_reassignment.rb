# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TicketOrganizationReassignment < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Organization Reassignment',
      name:        'ticket_organization_reassignment',
      area:        'Ticket::Base',
      description: 'Controls if by updating the primary organization of a user, the 100 most recent existing tickets for this user are updated as well.',
      options:     {
        form: [
          {
            display:   '',
            null:      false,
            name:      'ticket_organization_reassignment',
            tag:       'boolean',
            options:   {
              true  => 'The most recent tickets are updated.',
              false => 'No tickets are updated.',
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
