class UpdateObjectManager3 < ActiveRecord::Migration
  def up

    ObjectManager::Attribute.add(
      force: true,
      object: 'User',
      name: 'organization_id',
      display: 'Organization',
      data_type: 'autocompletion_ajax',
      data_option: {
        multiple: false,
        nulloption: true,
        null: true,
        relation: 'Organization',
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      position: 900,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      force: true,
      object: 'Ticket',
      name: 'customer_id',
      display: 'Customer',
      data_type: 'user_autocompletion',
      data_option: {
        relation: 'User',
        autocapitalize: false,
        multiple: false,
        null: false,
        limit: 200,
        placeholder: 'Enter Person or Organization/Company',
        minLengt: 2,
        translate: false,
      },
      editable: false,
      active: true,
      screens: {
        create_top: {
          Agent: {
            null: false,
          },
        },
        edit: {},
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 10,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

end
