# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4089FixDraftAttribute < ActiveRecord::Migration[5.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    field = ObjectManager::Attribute.find_by(name: 'shared_drafts', object_lookup_id: ObjectLookup.by_name('Group'))
    if !field
      add_field
      return
    end

    field.update(editable: false)
  end

  def add_field
    UserInfo.current_user_id = 1
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Group',
      name:        'shared_drafts',
      display:     'Shared Drafts',
      data_type:   'active',
      data_option: {
        null:       false,
        default:    true,
        permission: ['admin.group'],
      },
      editable:    false,
      active:      true,
      screens:     {
        create: {
          '-all-' => {
            null: true,
          },
        },
        edit:   {
          '-all-': {
            null: false,
          },
        },
        view:   {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1400,
    )
    ObjectManager::Attribute.migration_execute
  end
end
