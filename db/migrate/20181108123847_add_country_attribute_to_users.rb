# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Fixes issue #2333 - Object country already exists
# The country column already exists in the database, but there is no corresponding ObjectManager::Attribute for it
# This migration adds the User.country attribute if and only if it does not exist already
class AddCountryAttributeToUsers < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # return if the country attribute already exists
    current_country_attribute = ObjectManager::Attribute.find_by(object_lookup_id: ObjectLookup.by_name('User'), name: 'country')
    return if current_country_attribute.present?

    ObjectManager::Attribute.add(
      force:         true,
      object:        'User',
      name:          'country',
      display:       'Country',
      data_type:     'input',
      data_option:   {
        type:       'text',
        maxlength:  100,
        null:       true,
        item_class: 'formGroup--halfSize',
      },
      editable:      true,
      active:        false,
      screens:       {
        signup:          {},
        invite_agent:    {},
        invite_customer: {},
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
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      1325,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
