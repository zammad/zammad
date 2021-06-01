# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class OrganizationDomainBasedAssignment < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :organizations, :domain, :string, limit: 250, null: true, default: ''
    add_column :organizations, :domain_assignment, :boolean, null: false, default: false
    add_index :organizations, [:domain]

    # rubocop:disable Lint/BooleanSymbol
    ObjectManager::Attribute.add(
      force:         true,
      object:        'Organization',
      name:          'domain_assignment',
      display:       'Domain based assignment',
      data_type:     'boolean',
      data_option:   {
        null:       true,
        default:    false,
        note:       'Assign Users based on users domain.',
        item_class: 'formGroup--halfSize',
        options:    {
          true:  'yes',
          false: 'no',
        },
        translate:  true,
      },
      editable:      false,
      active:        true,
      screens:       {
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      1410,
      updated_by_id: 1,
      created_by_id: 1,
    )
    # rubocop:enable Lint/BooleanSymbol

    ObjectManager::Attribute.add(
      force:         true,
      object:        'Organization',
      name:          'domain',
      display:       'Domain',
      data_type:     'input',
      data_option:   {
        type:       'text',
        maxlength:  150,
        null:       true,
        item_class: 'formGroup--halfSize',
      },
      editable:      false,
      active:        true,
      screens:       {
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
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      1420,
      updated_by_id: 1,
      created_by_id: 1,
    )

    Cache.clear
  end
end
