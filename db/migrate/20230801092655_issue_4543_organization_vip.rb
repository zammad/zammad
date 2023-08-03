# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4543OrganizationVip < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :organizations do |t|
      t.boolean :vip, default: false, null: false
    end

    Organization.reset_column_information

    UserInfo.current_user_id = 1

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        'vip',
      display:     'VIP',
      data_type:   'boolean',
      data_option: {
        null:       true,
        default:    false,
        item_class: 'formGroup--halfSize',
        options:    {
          false => 'no',
          true  => 'yes',
        },
        translate:  true,
        permission: ['admin.organization'],
      },
      editable:    false,
      active:      true,
      screens:     {
        edit:   {
          '-all-' => {
            null: true,
          },
        },
        create: {
          '-all-' => {
            null: true,
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
      position:    1450,
    )
  end
end
