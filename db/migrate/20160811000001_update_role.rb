
class UpdateRole < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :roles, :preferences, :text, limit: 500.kilobytes + 1, null: true
    add_column :roles, :default_at_signup, :boolean, null: true, default: false

    Role.create_or_update(
      id: 1,
      name: 'Admin',
      note: 'To configure your system.',
      preferences: {
        not: ['Customer'],
      },
      default_at_signup: false,
      updated_by_id: 1,
      created_by_id: 1
    )
    Role.create_or_update(
      id: 2,
      name: 'Agent',
      note: 'To work on Tickets.',
      default_at_signup: false,
      preferences: {
        not: ['Customer'],
      },
      updated_by_id: 1,
      created_by_id: 1
    )
    Role.create_or_update(
      id: 3,
      name: 'Customer',
      note: 'People who create Tickets ask for help.',
      preferences: {
        not: %w(Agent Admin),
      },
      default_at_signup: true,
      updated_by_id: 1,
      created_by_id: 1
    )
    Role.create_or_update(
      id: 4,
      name: 'Report',
      note: 'Access the report area.',
      preferences: {
        not: ['Customer'],
      },
      default_at_signup: false,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      force: true,
      object: 'Organization',
      name: 'shared',
      display: 'Shared organization',
      data_type: 'boolean',
      data_option: {
        null: true,
        default: true,
        note: 'Customers in the organization can view each other items.',
        item_class: 'formGroup--halfSize',
        translate: true,
        options: {
          true: 'yes',
          false: 'no',
        }
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
            shown: true,
          },
        },
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 1400,
    )

    ObjectManager::Attribute.add(
      force: true,
      object: 'User',
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
            default: [Role.lookup(name: 'Agent').id],
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
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 1600,
    )

  end
end
