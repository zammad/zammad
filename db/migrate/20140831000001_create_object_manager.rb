class CreateObjectManager < ActiveRecord::Migration
  def up

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


    ObjectManager::Attribute.add(
      object: 'User',
      name: 'login',
      display: 'Login',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 100,
        null: true,
        autocapitalize: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {},
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 100,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'firstname',
      display: 'Firstname',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 200,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'lastname',
      display: 'Lastname',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 300,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'email',
      display: 'Email',
      data_type: 'input',
      data_option: {
        type: 'email',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {
          '-all-' => {
            null: false,
          },
        },
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 400,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'web',
      display: 'Web',
      data_type: 'input',
      data_option: {
        type: 'url',
        maxlength: 250,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      position: 500,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'phone',
      display: 'Phone',
      data_type: 'input',
      data_option: {
        type: 'phone',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      position: 600,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'mobile',
      display: 'Mobile',
      data_type: 'input',
      data_option: {
        type: 'phone',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      position: 700,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'fax',
      display: 'Fax',
      data_type: 'input',
      data_option: {
        type: 'phone',
        maxlength: 100,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      position: 800,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'organization_id',
      display: 'Organization',
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
      position: 900,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'department',
      display: 'Department',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 200,
        null: true,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      position: 1000,
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
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'password',
      display: 'Password',
      data_type: 'input',
      data_option: {
        type: 'password',
        maxlength: 100,
        null: true,
        autocomplete: 'off',
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        signup: {
          '-all-' => {
            null: false,
          },
        },
        invite_agent: {},
        edit: {
          Admin: {
            null: true,
          },
        },
        view: {}
      },
      pending_migration: false,
      position: 1400,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'vip',
      display: 'VIP',
      data_type: 'boolean',
      data_option: {
        null: true,
        default: false,
        item_class: 'formGroup--halfSize',
        options: {
          false: 'no',
          true: 'yes',
        },
        translate: true,
      },
      editable: false,
      active: true,
      screens: {
        edit: {
          Admin: {
            null: true,
          },
          Agent: {
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
      position: 1490,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'note',
      display: 'Note',
      data_type: 'richtext',
      data_option: {
        type: 'text',
        maxlength: 250,
        null: true,
        note: 'Notes are visible to agents only, never to customers.',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
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
      position: 1500,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'role_ids',
      display: 'Roles',
      data_type: 'checkbox',
      data_option: {
        multiple: true,
        null: false,
        relation: 'Role',
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1600,
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
          },
        },
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
      name: 'active',
      display: 'Active',
      data_type: 'active',
      data_option: {
        default: true,
      },
      editable: false,
      active: true,
      screens: {
        signup: {},
        invite_agent: {},
        edit: {
          Admin: {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1800,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'name',
      display: 'Name',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 150,
        null: false,
        item_class: 'formGroup--halfSize',
      },
      editable: false,
      active: true,
      screens: {
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: true,
          },
        },
      },
      pending_migration: false,
      position: 200,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'shared',
      display: 'Shared organization',
      data_type: 'boolean',
      data_option: {
        maxlength: 250,
        null: true,
        default: true,
        note: 'Customers in the organization can view each other items.',
        item_class: 'formGroup--halfSize',
        options: {
          true: 'Yes',
          false: 'No',
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
      pending_migration: false,
      position: 1400,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'note',
      display: 'Note',
      data_type: 'richtext',
      data_option: {
        type: 'text',
        maxlength: 250,
        null: true,
        note: 'Notes are visible to agents only, never to customers.',
      },
      editable: false,
      active: true,
      screens: {
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
      position: 1500,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      object: 'Organization',
      name: 'active',
      display: 'Active',
      data_type: 'active',
      data_option: {
        default: true,
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
            shown: false,
          },
        },
      },
      pending_migration: false,
      position: 1800,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

  def down
    drop_table :object_manager_attributes
  end
end
