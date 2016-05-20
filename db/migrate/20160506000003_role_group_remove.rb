
class RoleGroupRemove < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')
    object_lookup_id = ObjectLookup.by_name('User')
    record = ObjectManager::Attribute.find_by(
      object_lookup_id: object_lookup_id,
      name: 'role_ids',
    )
    record.destroy if record
    record = ObjectManager::Attribute.find_by(
      object_lookup_id: object_lookup_id,
      name: 'group_ids',
    )
    record.destroy if record

    ObjectManager::Attribute.create(
      object_lookup_id: ObjectLookup.by_name('User'),
      name: 'role_ids',
      display: 'Permissions',
      data_type: 'user_permission',
      data_option: {
        null: false,
        item_class: 'checkbox',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {
          '-all-' => {
            null: false,
            hideMode: {
              rolesSelected: ['Agent'],
              rolesNot: ['Customer'],
            }
          },
        },
        invite_customer: {},
        edit: {
          Admin: {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      position: 1600,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
