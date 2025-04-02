# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketConditionsRegularExpressionOperators < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Ticket Conditions Regular Expression Operators',
      name:        'ticket_conditions_allow_regular_expression_operators',
      area:        'Ticket::Core',
      description: 'Defines if the ticket conditions editor supports regular expression operators for triggers and ticket auto assignment.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'ticket_conditions_allow_regular_expression_operators',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        online_service_disable: true,
        permission:             ['admin.ticket'],
      },
      frontend:    true
    )
  end
end
