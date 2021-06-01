# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FormGroupSelection < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    group = Group.where(active: true).first
    if !group
      group = Group.first
    end
    group_id = 1
    if group
      group_id = group.id
    end
    Setting.create_if_not_exists(
      title:       'Group selection for Ticket creation',
      name:        'form_ticket_create_group_id',
      area:        'Form::Base',
      description: 'Defines if group of created tickets via web form.',
      options:     {
        form: [
          {
            display:  '',
            null:     true,
            name:     'form_ticket_create_group_id',
            tag:      'select',
            relation: 'Group',
          },
        ],
      },
      state:       group_id,
      preferences: {
        permission: ['admin.channel_formular'],
      },
      frontend:    false,
    )

    Setting.create_if_not_exists(
      title:       'Limit tickets by ip per hour',
      name:        'form_ticket_create_by_ip_per_hour',
      area:        'Form::Base',
      description: 'Defines limit of tickets by ip per hour via web form.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'form_ticket_create_by_ip_per_hour',
            tag:     'input',
          },
        ],
      },
      state:       20,
      preferences: {
        permission: ['admin.channel_formular'],
      },
      frontend:    false,
    )
    Setting.create_if_not_exists(
      title:       'Limit tickets by ip per day',
      name:        'form_ticket_create_by_ip_per_day',
      area:        'Form::Base',
      description: 'Defines limit of tickets by ip per day via web form.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'form_ticket_create_by_ip_per_day',
            tag:     'input',
          },
        ],
      },
      state:       240,
      preferences: {
        permission: ['admin.channel_formular'],
      },
      frontend:    false,
    )
    Setting.create_if_not_exists(
      title:       'Limit tickets per day',
      name:        'form_ticket_create_per_day',
      area:        'Form::Base',
      description: 'Defines limit of tickets per day via web form.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'form_ticket_create_per_day',
            tag:     'input',
          },
        ],
      },
      state:       5000,
      preferences: {
        permission: ['admin.channel_formular'],
      },
      frontend:    false,
    )

  end
end
