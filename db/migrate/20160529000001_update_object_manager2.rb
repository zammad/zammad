class UpdateObjectManager2 < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :object_manager_attributes, :to_config, :boolean, null: false, default: false
    add_column :object_manager_attributes, :data_option_new, :string, limit: 8000, null: true, default: false

    UserInfo.current_user_id = 1
    ObjectManager::Attribute.add(
      force: true,
      object: 'User',
      name: 'phone',
      display: 'Phone',
      data_type: 'input',
      data_option: {
        type: 'tel',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        invite_customer: {},
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
      position: 600,
    )

    ObjectManager::Attribute.add(
      force: true,
      object: 'User',
      name: 'mobile',
      display: 'Mobile',
      data_type: 'input',
      data_option: {
        type: 'tel',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        invite_customer: {},
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
      position: 700,
    )

    ObjectManager::Attribute.add(
      force: true,
      object: 'User',
      name: 'fax',
      display: 'Fax',
      data_type: 'input',
      data_option: {
        type: 'tel',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        invite_customer: {},
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
      position: 800,
    )

  end
end
