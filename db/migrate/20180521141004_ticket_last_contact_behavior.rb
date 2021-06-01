# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketLastContactBehavior < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Last Contact Behaviour',
      name:        'ticket_last_contact_behaviour',
      area:        'Ticket::Base',
      description: 'Sets the last customer contact based on the last contact of a customer or on the last contact of a customer to whom an agent has not yet responded.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ticket_last_contact_behaviour',
            tag:       'select',
            translate: true,
            options:   {
              'based_on_customer_reaction'     => 'Last customer contact (without consideration an agent has replied to it)',
              'check_if_agent_already_replied' => 'Last customer contact (with consideration an agent has replied to it)',
            },
          },
        ],
      },
      state:       'check_if_agent_already_replied',
      preferences: {
        permission: ['admin.ticket'],
      },
      frontend:    false
    )
  end
end
