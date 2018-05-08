class ChangeObjectManagerAttributes < ActiveRecord::Migration[5.1]
  def change
    return if !Setting.find_by(name: 'system_init_done')

    UserInfo.current_user_id = 1

    ObjectManager::Attribute.add(
        force: true,
        object: 'User',
        name: 'organization_id',
        display: 'Primary Organization',
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
            invite_customer: {
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
        position: 900,
    )

    ObjectManager::Attribute.add(
        force: true,
        object: 'User',
        name: 'organization_ids',
        display: 'Alternative Organizations',
        data_type: 'autocompletion_multiple_ajax',
        data_option: {
            multiple: true,
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
            invite_customer: {
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
        position: 900,
    )

  end
end
