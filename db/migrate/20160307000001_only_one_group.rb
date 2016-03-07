
class OnlyOneGroup < ActiveRecord::Migration
  def up
    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'group_id',
      display: 'Group',
      data_type: 'select',
      data_option: {
        relation: 'Group',
        relation_condition: { access: 'rw' },
        nulloption: true,
        multiple: false,
        null: false,
        translate: false,
        only_shown_if_selectable: true,
      },
      editable: false,
      active: true,
      screens: {
        create_middle: {
          '-all-' => {
            null: false,
            item_class: 'column',
          },
        },
        edit: {
          Agent: {
            null: false,
          },
        },
      },
      pending_migration: false,
      position: 25,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object: 'User',
      name: 'group_ids',
      display: 'Groups',
      data_type: 'checkbox',
      data_option: {
        multiple: true,
        null: true,
        relation: 'Group',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {
          '-all-' => {
            null: false,
            only_shown_if_selectable: true,
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
      pending_migration: false,
      position: 1700,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object: 'User',
      name: 'street',
      display: 'Street',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
      },
      editable: true,
      active: false,
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
      pending_migration: false,
      position: 1100,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'zip',
      display: 'Zip',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: true,
      active: false,
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
      pending_migration: false,
      position: 1200,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'city',
      display: 'City',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: true,
      active: false,
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
      pending_migration: false,
      position: 1300,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'address',
      display: 'Address',
      data_type: 'textarea',
      data_option: {
        type: 'text',
        maxlength: 500,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: true,
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
      pending_migration: false,
      position: 1350,
      created_by_id: 1,
      updated_by_id: 1,
    )

    list = []
    User.all {|user|
      next if !user.zip.empty? && !user.city.empty? && !user.street.empty?
      #next if !user.address.empty?
      list.push user
    }
    list
  end

end
