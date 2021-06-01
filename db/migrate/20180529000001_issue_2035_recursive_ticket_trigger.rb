# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2035RecursiveTicketTrigger < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Recursive Ticket Triggers',
      name:        'ticket_trigger_recursive',
      area:        'Ticket::Core',
      description: 'Activate the recursive processing of ticket triggers.',
      options:     {
        form: [
          {
            display: 'Recursive Ticket Triggers',
            null:    true,
            name:    'ticket_trigger_recursive',
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
    Setting.create_if_not_exists(
      title:       'Recursive Ticket Triggers Loop Max.',
      name:        'ticket_trigger_recursive_max_loop',
      area:        'Ticket::Core',
      description: 'Maximum number of recursively executed triggers.',
      options:     {
        form: [
          {
            display: 'Recursive Ticket Triggers',
            null:    true,
            name:    'ticket_trigger_recursive_max_loop',
            tag:     'select',
            options: {
              1  => ' 1',
              2  => ' 2',
              3  => ' 3',
              4  => ' 4',
              5  => ' 5',
              6  => ' 6',
              7  => ' 7',
              8  => ' 8',
              9  => ' 9',
              10 => '10',
              11 => '11',
              12 => '12',
              13 => '13',
              14 => '14',
              15 => '15',
              16 => '16',
              17 => '17',
              18 => '18',
              19 => '19',
              20 => '20',
            },
          },
        ],
      },
      state:       10,
      preferences: {
        permission: ['admin.ticket'],
        hidden:     true,
      },
      frontend:    false
    )

  end
end
