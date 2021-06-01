# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManagerUserEmailOptional < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      force:       true,
      object:      'User',
      name:        'email',
      display:     'Email',
      data_type:   'input',
      data_option: {
        type:       'email',
        maxlength:  150,
        null:       true,
        item_class: 'formGroup--halfSize',
      },
      editable:    false,
      active:      true,
      screens:     {
        signup:          {
          '-all-' => {
            null: false,
          },
        },
        invite_agent:    {
          '-all-' => {
            null: false,
          },
        },
        invite_customer: {
          '-all-' => {
            null: false,
          },
        },
        edit:            {
          '-all-' => {
            null: true,
          },
        },
        view:            {
          '-all-' => {
            shown: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    400,
    )
  end
end
