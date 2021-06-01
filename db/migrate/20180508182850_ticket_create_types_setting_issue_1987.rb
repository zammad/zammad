# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketCreateTypesSettingIssue1987 < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Default type for a new ticket',
      name:        'ui_ticket_create_default_type',
      area:        'UI::TicketCreate',
      description: 'Select default ticket type',
      options:     {
        form: [
          {
            display:  '',
            null:     false,
            multiple: false,
            name:     'ui_ticket_create_default_type',
            tag:      'select',
            options:  {
              'phone-in'  => '1. Phone inbound',
              'phone-out' => '2. Phone outbound',
              'email-out' => '3. Email outbound',
            },
          },
        ],
      },
      state:       'phone-in',
      preferences: {
        permission: ['admin.ui']
      },
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Available types for a new ticket',
      name:        'ui_ticket_create_available_types',
      area:        'UI::TicketCreate',
      description: 'Set available ticket types',
      options:     {
        form: [
          {
            display:  '',
            null:     false,
            multiple: true,
            name:     'ui_ticket_create_available_types',
            tag:      'select',
            options:  {
              'phone-in'  => '1. Phone inbound',
              'phone-out' => '2. Phone outbound',
              'email-out' => '3. Email outbound',
            },
          },
        ],
      },
      state:       %w[phone-in phone-out email-out],
      preferences: {
        permission: ['admin.ui']
      },
      frontend:    true
    )
  end
end
