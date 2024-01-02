# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class AddTicketDuplicateDetection < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Detect Duplicate Ticket Creation',
      name:        'ticket_duplicate_detection',
      area:        'Web::TicketDuplicateDetection',
      description: 'Enables a warning to users during ticket creation if there is an existing ticket with the same attributes.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'ticket_duplicate_detection',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection'],
      },
      state:       false,
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Attributes to compare',
      name:        'ticket_duplicate_detection_attributes',
      area:        'Web::TicketDuplicateDetection',
      description: 'Defines which ticket attributes are checked before creating a ticket.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection'],
      },
      state:       [],
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Warning title',
      name:        'ticket_duplicate_detection_title',
      area:        'Web::TicketDuplicateDetection',
      description: 'Defines the warning title that is shown when a matching ticket is present.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection'],
      },
      state:       'Similar tickets found',
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Warning message',
      name:        'ticket_duplicate_detection_body',
      area:        'Web::TicketDuplicateDetection',
      description: 'Defines the warning message that is shown when a matching ticket is present.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection'],
      },
      state:       'Tickets with the same attributes were found.',
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Show to user roles',
      name:        'ticket_duplicate_detection_role_ids',
      area:        'Web::TicketDuplicateDetection',
      description: 'Defines which user roles will receive a warning in case of matching tickets.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection'],
      },
      state:       [2],
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Show matching tickets in the warning',
      name:        'ticket_duplicate_detection_show_tickets',
      area:        'Web::TicketDuplicateDetection',
      description: 'Defines whether the matching tickets are shown in case of already existing tickets.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection'],
      },
      state:       true,
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Permission level for looking up tickets',
      name:        'ticket_duplicate_detection_permission_level',
      area:        'Web::TicketDuplicateDetection',
      description: 'Defines the permission level used for lookups.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection'],
      },
      state:       'user',
      frontend:    true
    )
    Setting.create_if_not_exists(
      title:       'Match tickets in following states',
      name:        'ticket_duplicate_detection_search',
      area:        'Web::TicketDuplicateDetection',
      description: 'Defines the ticket states used for lookups.',
      options:     {
        form: [
          {},
        ],
      },
      state:       'all',
      preferences: {
        authentication: true,
        permission:     ['admin.ticket_duplicate_detection']
      },
      frontend:    true
    )
    CoreWorkflow.create_if_not_exists(
      name:            'base - ticket duplicate detection with same attributes',
      object:          'Ticket',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::TicketDuplicateDetection',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::TicketDuplicateDetection']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end
end
