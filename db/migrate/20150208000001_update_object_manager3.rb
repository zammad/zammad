class UpdateObjectManager3 < ActiveRecord::Migration
  def up

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'active',
      display: 'Active',
      data_type: 'active',
      data_option: {
        default: true,
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      pending_migration: false,
      position: 1800,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'active',
      display: 'Active',
      data_type: 'active',
      data_option: {
        default: true,
      },
      editable: false,
      active: true,
      screens: {
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
      pending_migration: false,
      position: 1800,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'password',
      display: 'Password',
      data_type: 'input',
      data_option: {
        type: 'password',
        maxlength: 100,
        null: true,
        autocomplete: 'off',
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {},
        edit: {
          Admin: {
            null: true,
          },
        },
        view: {}
      },
      pending_migration: false,
      position: 1400,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

  def down
  end
end
