# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ObjectManagerTicketObjectUpdate < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    UserInfo.current_user_id = 1
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'number',
      display:     '#',
      data_type:   'input',
      data_option: {
        type:      'text',
        readonly:  1,
        null:      true,
        maxlength: 60,
        width:     '68px',
      },
      editable:    false,
      active:      true,
      screens:     {
        create_top: {},
        edit:       {},
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    5,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'title',
      display:     'Title',
      data_type:   'input',
      data_option: {
        type:      'text',
        maxlength: 200,
        null:      false,
        translate: false,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_top: {
          '-all-' => {
            null: false,
          },
        },
        edit:       {},
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    8,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'organization_id',
      display:     'Organization',
      data_type:   'autocompletion_ajax',
      data_option: {
        relation:       'Organization',
        autocapitalize: false,
        multiple:       false,
        null:           true,
        translate:      false,
        permission:     ['ticket.agent'],
        readonly:       1,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_top: {
          '-all-' => {
            null: false,
          },
        },
        edit:       {},
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    12,
    )
  end
end
