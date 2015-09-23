class CreateObjectManager < ActiveRecord::Migration
  def up
    add_column :tickets, :pending_time,  :timestamp,  null: true
    add_index :tickets, [:pending_time]

    add_column :tickets, :type,  :string, limit: 100, null: true
    add_index :tickets, [:type]

    create_table :object_manager_attributes do |t|
      t.references :object_lookup,                            null: false
      t.column :name,               :string, limit: 200,   null: false
      t.column :display,            :string, limit: 200,   null: false
      t.column :data_type,          :string, limit: 100,   null: false
      t.column :data_option,        :string, limit: 8000,  null: true
      t.column :editable,           :boolean,                 null: false, default: true
      t.column :active,             :boolean,                 null: false, default: true
      t.column :screens,            :string, limit: 2000,  null: true
      t.column :pending_migration,  :boolean,                 null: false, default: true
      t.column :position,           :integer,                 null: false
      t.column :created_by_id,      :integer,                 null: false
      t.column :updated_by_id,      :integer,                 null: false
      t.timestamps
    end
    add_index :object_manager_attributes, [:object_lookup_id, :name],   unique: true
    add_index :object_manager_attributes, [:object_lookup_id]

    ObjectManager::Attribute.add(
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
      pending_migration: false,
      position: 10,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'type',
      display: 'Type',
      data_type: 'select',
      data_option: {
        options: {
          'Incident' => 'Incident',
          'Problem'  => 'Problem',
          'Request for Change' => 'Request for Change',
        },
        nulloption: true,
        multiple: false,
        null: true,
        translate: true,
      },
      editable: false,
      active: false,
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
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
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
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'owner_id',
      display: 'Owner',
      data_type: 'select',
      data_option: {
        relation: 'User',
        relation_condition: { roles: 'Agent' },
        nulloption: true,
        multiple: false,
        null: true,
        translate: false,
      },
      editable: false,
      active: true,
      screens: {
        create_middle: {
          Agent: {
            null: true,
            item_class: 'column',
          },
        },
        edit: {
          Agent: {
            null: true,
          },
        },
      },
      pending_migration: false,
      position: 30,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'state_id',
      display: 'State',
      data_type: 'select',
      data_option: {
        relation: 'TicketState',
        nulloption: true,
        multiple: false,
        null: false,
        default: 2,
        translate: true,
        filter: [1, 2, 3, 4, 7],
      },
      editable: false,
      active: true,
      screens: {
        create_middle: {
          Agent: {
            null: false,
            item_class: 'column',
          },
          Customer: {
            item_class: 'column',
            nulloption: false,
            null: true,
            filter: [1, 4],
            default: 1,
          },
        },
        edit: {
          Agent: {
            nulloption: false,
            null: false,
            filter: [2, 3, 4, 7],
          },
          Customer: {
            nulloption: false,
            null: true,
            filter: [2, 4],
            default: 2,
          },
        },
      },
      pending_migration: false,
      position: 40,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'pending_time',
      display: 'Pending till',
      data_type: 'datetime',
      data_option: {
        future: true,
        past: false,
        diff: 24,
        null: true,
        translate: true,
        required_if: {
          state_id: [3, 7]
        },
        shown_if: {
          state_id: [3, 7]
        },
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
      position: 41,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'priority_id',
      display: 'Priority',
      data_type: 'select',
      data_option: {
        relation: 'TicketPriority',
        nulloption: true,
        multiple: false,
        null: false,
        default: 2,
        translate: true,
      },
      editable: false,
      active: true,
      screens: {
        create_middle: {
          Agent: {
            null: false,
            item_class: 'column',
          },
        },
        edit: {
          Agent: {
            null: false,
            nulloption: false,
          },
        },
      },
      pending_migration: false,
      position: 80,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'tags',
      display: 'Tags',
      data_type: 'tag',
      data_option: {
        type: 'text',
        null: true,
        translate: false,
      },
      editable: false,
      active: true,
      screens: {
        create_bottom: {
          Agent: {
            null: true,
          },
        },
        edit: {},
      },
      pending_migration: false,
      position: 900,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'title',
      display: 'Title',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 200,
        null: false,
        translate: false,
      },
      editable: false,
      active: true,
      screens: {
        create_top: {
          '-all-' => {
            null: false,
          },
        },
        edit: {},
      },
      pending_migration: false,
      position: 15,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'TicketArticle',
      name: 'type_id',
      display: 'Type',
      data_type: 'select',
      data_option: {
        relation: 'TicketArticleType',
        nulloption: false,
        multiple: false,
        null: false,
        default: 9,
        translate: true,
      },
      editable: false,
      active: true,
      screens: {
        create_middle: {},
        edit: {
          Agent: {
            null: false,
          },
        },
      },
      pending_migration: false,
      position: 100,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'TicketArticle',
      name: 'internal',
      display: 'Visibility',
      data_type: 'select',
      data_option: {
        options: { true: 'internal', false: 'public' },
        nulloption: false,
        multiple: false,
        null: true,
        default: false,
        translate: true,
      },
      editable: false,
      active: true,
      screens: {
        create_middle: {},
        edit: {
          Agent: {
            null: false,
          },
        },
      },
      pending_migration: false,
      position: 200,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'TicketArticle',
      name: 'to',
      display: 'To',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 1000,
        null: true,
      },
      editable: false,
      active: true,
      screens: {
        create_middle: {},
        edit: {
          Agent: {
            null: true,
          },
        },
      },
      pending_migration: false,
      position: 300,
      created_by_id: 1,
      updated_by_id: 1,
    )
    ObjectManager::Attribute.add(
      object: 'TicketArticle',
      name: 'cc',
      display: 'Cc',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 1000,
        null: true,
      },
      editable: false,
      active: true,
      screens: {
        create_phone_in: {},
        create_phone_out: {},
        create_email_out: {
          '-all-' => {
            null: true,
          }
        },
        create_middle: {},
        edit: {
          Agent: {
            null: true,
          },
        },
      },
      pending_migration: false,
      position: 400,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'TicketArticle',
      name: 'body',
      display: 'Text',
      data_type: 'richtext',
      data_option: {
        type: 'richtext',
        maxlength: 20_000,
        upload: true,
        rows: 8,
        null: true,
      },
      editable: false,
      active: true,
      screens: {
        create_top: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          Agent: {
            null: true,
          },
          Customer: {
            null: false,
          },
        },
      },
      pending_migration: false,
      position: 600,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

  def down
    drop_table :object_manager_attributes
  end
end
