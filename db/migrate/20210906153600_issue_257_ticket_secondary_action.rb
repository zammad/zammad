# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue257TicketSecondaryAction < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Tab behaviour after ticket action',
      name:        'ticket_secondary_action',
      area:        'CustomerWeb::Base',
      description: 'Defines the tab behaviour after a ticket action.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'ticket_secondary_action',
            tag:     'boolean',
            options: {
              'closeTab'              => 'Close tab',
              'closeTabOnTicketClose' => 'Close tab on ticket close',
              'closeNextInOverview'   => 'Next in overview',
              'stayOnTab'             => 'Stay on tab',
            },
          },
        ],
      },
      state:       'stayOnTab',
      preferences: {
        authentication: true,
        permission:     ['admin.channel_web'],
      },
      frontend:    true
    )
  end
end
