class UpdateObjectManager < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :object_manager_attributes, :to_create, :boolean, null: false, default: false
    add_column :object_manager_attributes, :to_migrate, :boolean, null: false, default: false
    add_column :object_manager_attributes, :to_delete, :boolean, null: false, default: false
    ObjectManager::Attribute.reset_column_information
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'name',
      display: 'Name',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 150,
        null: false,
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 200,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'assignment_timeout',
      display: 'Assignment Timeout',
      data_type: 'integer',
      data_option: {
        maxlength: 150,
        null: true,
        note: 'Assignment timeout in minutes if assigned agent is not working on it. Ticket will be shown as unassigend.',
        min: 0,
        max: 999_999,
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit: {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 300,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'follow_up_possible',
      display: 'Follow up possible',
      data_type: 'select',
      data_option: {
        default: 'yes',
        options: {
          yes: 'yes',
          reject: 'reject follow up/do not reopen Ticket',
          new_ticket: 'do not reopen Ticket but create new Ticket'
        },
        null: false,
        note: 'Follow up for closed ticket possible or not.',
        translate: true
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit: {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 400,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'follow_up_assignment',
      display: 'Assign Follow Ups',
      data_type: 'select',
      data_option: {
        default: 'yes',
        options: {
          true: 'yes',
          false: 'no',
        },
        null: false,
        note: 'Assign follow up to latest agent again.',
        translate: true
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit: {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 500,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'email_address_id',
      display: 'Email',
      data_type: 'select',
      data_option: {
        default: '',
        multiple: false,
        null: true,
        relation: 'EmailAddress',
        nulloption: true,
        do_not_log: true,
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit: {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 600,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'signature_id',
      display: 'Signature',
      data_type: 'select',
      data_option: {
        default: '',
        multiple: false,
        null: true,
        relation: 'Signature',
        nulloption: true,
        do_not_log: true,
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit: {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 600,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'note',
      display: 'Note',
      data_type: 'richtext',
      data_option: {
        type: 'text',
        maxlength: 250,
        null: true,
        note: 'Notes are visible to agents only, never to customers.',
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 1500,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      force: true,
      object: 'Group',
      name: 'active',
      display: 'Active',
      data_type: 'active',
      data_option: {
        null: true,
        default: true,
      },
      editable: false,
      active: true,
      screens: {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 1800,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end
end
