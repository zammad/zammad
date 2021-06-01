# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingTicketNumberIgnoreSystemIdSupport < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Number ignore system_id',
      name:        'ticket_number_ignore_system_id',
      area:        'Ticket::Core',
      description: '-',
      options:     {
        form: [
          {
            display: 'Ignore system_id',
            null:    true,
            name:    'ticket_number_ignore_system_id',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        permission: ['admin.ticket'],
        hidden:     true,
      },
      frontend:    false
    )
  end

end
