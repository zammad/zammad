# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class GroupHierarchy < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    rename_custom_object_attributes
    migrate_groups_table
    migrate_group_name
    update_name_last_column
    migrate_object_attributes
    change_group_field
    add_core_workflow_parent_id
    add_core_workflow_group_ids
    migrate_settings
  end

  def rename_custom_object_attributes
    MigrationHelper.rename_custom_object_attribute('Group', 'name_last')
    MigrationHelper.rename_custom_object_attribute('Group', 'parent_id')
  end

  def migrate_groups_table
    change_column :groups, :name, :string, limit: (160 * 6) + (2 * 5) # max depth of 6 and 5 delimiters inbetween
    add_column :groups, :name_last, :string, limit: 160, null: true # optional for now
    add_column :groups, :parent_id, :integer, null: true
    add_foreign_key :groups, :groups, column: :parent_id

    Group.reset_column_information
  end

  def migrate_group_name
    Group.all.each do |group|
      if group.name.exclude?('::')
        group.update!(name_last: group.name, updated_by_id: 1)

        next
      end

      try      = 1
      new_name = group.name

      loop do
        new_name = group.name.gsub(%r{::}, '-' * try)
        break if !Group.exists?(name: new_name)

        try += 1
      end

      group.update!(name: new_name, name_last: new_name, updated_by_id: 1)
    end
  end

  def update_name_last_column
    change_column :groups, :name_last, :string, limit: 160, null: false

    Group.reset_column_information
  end

  def migrate_object_attributes
    name_attribute = ObjectManager::Attribute.for_object('Group').find_by(name: 'name')
    name_attribute.data_option = { type: 'text', maxlength: 255, readonly: 1 }
    name_attribute.screens = {}
    name_attribute.save!

    ObjectManager::Attribute.add(
      force:         true,
      object:        'Group',
      name:          'name_last',
      display:       'Name',
      data_type:     'input',
      data_option:   {
        type:      'text',
        maxlength: 150,
        null:      false,
      },
      editable:      false,
      active:        true,
      screens:       {
        create: {
          '-all-' => {
            null: false,
          },
        },
        edit:   {
          '-all-' => {
            null: false,
          },
        },
        view:   {
          '-all-' => {
            shown: true,
          },
        },
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      210,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      force:         true,
      object:        'Group',
      name:          'parent_id',
      display:       'Parent group',
      data_type:     'tree_select',
      data_option:   {
        default:    '',
        null:       true,
        relation:   'Group',
        nulloption: true,
        do_not_log: true,
      },
      editable:      false,
      active:        true,
      screens:       {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit:   {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      250,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      force:         true,
      object:        'User',
      name:          'group_ids',
      display:       'Group permissions',
      data_type:     'group_permissions',
      data_option:   {
        null:       false,
        item_class: 'checkbox',
        permission: ['admin.user'],
      },
      editable:      false,
      active:        true,
      screens:       {
        signup:          {},
        invite_agent:    {
          '-all-' => {
            null: false,
          },
        },
        invite_customer: {},
        edit:            {
          '-all-' => {
            null: true,
          },
        },
        create:          {
          '-all-' => {
            null: true,
          },
        },
        view:            {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      1700,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute
      .get(
        object: 'User',
        name:   'role_ids',
      )
      .update!(display: 'Roles')
  end

  def change_group_field
    ObjectManager::Attribute.for_object('Ticket').find_by(name: 'group_id').update(data_type: 'tree_select')
  end

  def add_core_workflow_parent_id
    CoreWorkflow.create_if_not_exists(
      name:            'base - remove current and child groups from parent id',
      object:          'Group',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::AdminGroupParentId',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::AdminGroupParentId']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end

  def add_core_workflow_group_ids
    CoreWorkflow.create_if_not_exists(
      name:            'base - show group list for agents',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::AdminShowGroupListForAgents',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::AdminShowGroupListForAgents']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end

  def migrate_settings
    setting = Setting.find_by(name: 'customer_ticket_create_group_ids')
    return if setting.blank?

    setting.options['form'][0]['tag'] = 'tree_select'
    setting.save!
  end
end
