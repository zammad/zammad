# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class FixedAdminUserPermission920 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'customer_id',
      display:     'Customer',
      data_type:   'user_autocompletion',
      data_option: {
        relation:       'User',
        autocapitalize: false,
        multiple:       false,
        guess:          true,
        null:           false,
        limit:          200,
        placeholder:    'Enter Person or Organization/Company',
        minLengt:       2,
        translate:      false,
        permission:     ['ticket.agent'],
      },
      editable:    false,
      active:      true,
      screens:     {
        create_top: {
          '-all-' => {
            null: false,
          },
        },
        edit:       {},
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    10,
    )
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'type',
      display:     'Type',
      data_type:   'select',
      data_option: {
        default:    '',
        options:    {
          'Incident'           => 'Incident',
          'Problem'            => 'Problem',
          'Request for Change' => 'Request for Change',
        },
        nulloption: true,
        multiple:   false,
        null:       true,
        translate:  true,
      },
      editable:    true,
      active:      false,
      screens:     {
        create_middle: {
          '-all-' => {
            null:       false,
            item_class: 'column',
          },
        },
        edit:          {
          'ticket.agent' => {
            null: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    20,
    )
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'group_id',
      display:     'Group',
      data_type:   'select',
      data_option: {
        default:                  '',
        relation:                 'Group',
        relation_condition:       { access: 'full' },
        nulloption:               true,
        multiple:                 false,
        null:                     false,
        translate:                false,
        only_shown_if_selectable: true,
        permission:               ['ticket.agent', 'ticket.customer'],
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {
          '-all-' => {
            null:       false,
            item_class: 'column',
          },
        },
        edit:          {
          'ticket.agent' => {
            null: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    25,
    )
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'owner_id',
      display:     'Owner',
      data_type:   'select',
      data_option: {
        default:            '',
        relation:           'User',
        relation_condition: { roles: 'Agent' },
        nulloption:         true,
        multiple:           false,
        null:               true,
        translate:          false,
        permission:         ['ticket.agent'],
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {
          '-all-' => {
            null:       true,
            item_class: 'column',
          },
        },
        edit:          {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    30,
    )
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'state_id',
      display:     'State',
      data_type:   'select',
      data_option: {
        relation:   'TicketState',
        nulloption: true,
        multiple:   false,
        null:       false,
        default:    Ticket::State.find_by(default_follow_up: true).id,
        translate:  true,
        filter:     Ticket::State.by_category(:viewable).pluck(:id),
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {
          'ticket.agent'    => {
            null:       false,
            item_class: 'column',
            filter:     Ticket::State.by_category(:viewable_agent_new).pluck(:id),
          },
          'ticket.customer' => {
            item_class: 'column',
            nulloption: false,
            null:       true,
            filter:     Ticket::State.by_category(:viewable_customer_new).pluck(:id),
            default:    Ticket::State.find_by(name: 'new').id,
          },
        },
        edit:          {
          'ticket.agent'    => {
            nulloption: false,
            null:       false,
            filter:     Ticket::State.by_category(:viewable_agent_edit).pluck(:id),
          },
          'ticket.customer' => {
            nulloption: false,
            null:       true,
            filter:     Ticket::State.by_category(:viewable_customer_edit).pluck(:id),
            default:    Ticket::State.find_by(name: 'open').id,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    40,
    )
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'pending_time',
      display:     'Pending till',
      data_type:   'datetime',
      data_option: {
        future:      true,
        past:        false,
        diff:        24,
        null:        true,
        translate:   true,
        required_if: {
          state_id: Ticket::State.by_category(:pending).pluck(:id),
        },
        shown_if:    {
          state_id: Ticket::State.by_category(:pending).pluck(:id),
        },
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {
          '-all-' => {
            null:       false,
            item_class: 'column',
          },
        },
        edit:          {
          '-all-' => {
            null: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    41,
    )
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'priority_id',
      display:     'Priority',
      data_type:   'select',
      data_option: {
        relation:   'TicketPriority',
        nulloption: false,
        multiple:   false,
        null:       false,
        default:    Ticket::Priority.find_by(default_create: true).id,
        translate:  true,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {
          'ticket.agent' => {
            null:       false,
            item_class: 'column',
          },
        },
        edit:          {
          'ticket.agent' => {
            null: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    80,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'tags',
      display:     'Tags',
      data_type:   'tag',
      data_option: {
        type:      'text',
        null:      true,
        translate: false,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_bottom: {
          'ticket.agent' => {
            null: true,
          },
        },
        edit:          {},
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    900,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'TicketArticle',
      name:        'type_id',
      display:     'Type',
      data_type:   'select',
      data_option: {
        relation:   'TicketArticleType',
        nulloption: false,
        multiple:   false,
        null:       false,
        default:    Ticket::Article::Type.lookup(name: 'note').id,
        translate:  true,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {},
        edit:          {
          'ticket.agent' => {
            null: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    100,
    )

    # rubocop:disable Lint/BooleanSymbol
    ObjectManager::Attribute.add(
      force:       true,
      object:      'TicketArticle',
      name:        'internal',
      display:     'Visibility',
      data_type:   'select',
      data_option: {
        options:    {
          true:  'internal',
          false: 'public'
        },
        nulloption: false,
        multiple:   false,
        null:       true,
        default:    false,
        translate:  true,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {},
        edit:          {
          'ticket.agent' => {
            null: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    200,
    )
    # rubocop:enable Lint/BooleanSymbol

    ObjectManager::Attribute.add(
      force:       true,
      object:      'TicketArticle',
      name:        'to',
      display:     'To',
      data_type:   'input',
      data_option: {
        type:      'text',
        maxlength: 1000,
        null:      true,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {},
        edit:          {
          'ticket.agent' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    300,
    )
    ObjectManager::Attribute.add(
      force:       true,
      object:      'TicketArticle',
      name:        'cc',
      display:     'Cc',
      data_type:   'input',
      data_option: {
        type:      'text',
        maxlength: 1000,
        null:      true,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_top:    {},
        create_middle: {},
        edit:          {
          'ticket.agent' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    400,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'TicketArticle',
      name:        'body',
      display:     'Text',
      data_type:   'richtext',
      data_option: {
        type:      'richtext',
        maxlength: 20_000,
        upload:    true,
        rows:      8,
        null:      true,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_top: {
          '-all-' => {
            null: false,
          },
        },
        edit:       {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    600,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'User',
      name:        'password',
      display:     'Password',
      data_type:   'input',
      data_option: {
        type:         'password',
        maxlength:    100,
        null:         true,
        autocomplete: 'off',
        item_class:   'formGroup--halfSize',
      },
      editable:    false,
      active:      true,
      screens:     {
        signup:          {
          '-all-' => {
            null: false,
          },
        },
        invite_agent:    {},
        invite_customer: {},
        edit:            {
          'admin.user' => {
            null: true,
          },
        },
        view:            {}
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1400,
    )

    # rubocop:disable Lint/BooleanSymbol
    ObjectManager::Attribute.add(
      force:       true,
      object:      'User',
      name:        'vip',
      display:     'VIP',
      data_type:   'boolean',
      data_option: {
        null:       true,
        default:    false,
        item_class: 'formGroup--halfSize',
        options:    {
          false: 'no',
          true:  'yes',
        },
        translate:  true,
        permission: ['admin.user', 'ticket.agent'],
      },
      editable:    false,
      active:      true,
      screens:     {
        edit: {
          '-all-' => {
            null: true,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1490,
    )
    # rubocop:enable Lint/BooleanSymbol

    ObjectManager::Attribute.add(
      force:       true,
      object:      'User',
      name:        'role_ids',
      display:     'Permissions',
      data_type:   'user_permission',
      data_option: {
        null:       false,
        item_class: 'checkbox',
        permission: ['admin.user'],
      },
      editable:    false,
      active:      true,
      screens:     {
        signup:          {},
        invite_agent:    {
          '-all-' => {
            null:    false,
            default: [Role.lookup(name: 'Agent').id],
          },
        },
        invite_customer: {},
        edit:            {
          '-all-' => {
            null: true,
          },
        },
        view:            {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1600,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'User',
      name:        'active',
      display:     'Active',
      data_type:   'active',
      data_option: {
        null:       true,
        default:    true,
        permission: ['admin.user', 'ticket.agent'],
      },
      editable:    false,
      active:      true,
      screens:     {
        signup:          {},
        invite_agent:    {},
        invite_customer: {},
        edit:            {
          '-all-' => {
            null: false,
          },
        },
        view:            {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1800,
    )

    # rubocop:disable Lint/BooleanSymbol
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        'shared',
      display:     'Shared organization',
      data_type:   'boolean',
      data_option: {
        null:       true,
        default:    true,
        note:       'Customers in the organization can view each other items.',
        item_class: 'formGroup--halfSize',
        options:    {
          true:  'yes',
          false: 'no',
        },
        translate:  true,
        permission: ['admin.organization'],
      },
      editable:    false,
      active:      true,
      screens:     {
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
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1400,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        'domain_assignment',
      display:     'Domain based assignment',
      data_type:   'boolean',
      data_option: {
        null:       true,
        default:    false,
        note:       'Assign Users based on users domain.',
        item_class: 'formGroup--halfSize',
        options:    {
          true:  'yes',
          false: 'no',
        },
        translate:  true,
        permission: ['admin.organization'],
      },
      editable:    false,
      active:      true,
      screens:     {
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
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1410,
    )
    # rubocop:enable Lint/BooleanSymbol

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Organization',
      name:        'active',
      display:     'Active',
      data_type:   'active',
      data_option: {
        null:       true,
        default:    true,
        permission: ['admin.organization'],
      },
      editable:    false,
      active:      true,
      screens:     {
        edit: {
          '-all-' => {
            null: false,
          },
        },
        view: {
          '-all-' => {
            shown: false,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1800,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Group',
      name:        'active',
      display:     'Active',
      data_type:   'active',
      data_option: {
        null:       true,
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
      position:    1800,
    )

    map = {
      Admin:    'admin',
      Agent:    'ticket.agent',
      Customer: 'ticket.customer',
    }
    ObjectManager::Attribute.all.each do |attribute|
      next if attribute.screens.blank?

      screens = {}
      attribute.screens.each do |screen, role_value|
        if role_value.blank?
          screens[screen] = role_value
        else
          screens[screen] = {}
          role_value.each do |role, value|
            if map[role.to_sym]
              screens[screen][map[role.to_sym]] = value
            else
              screens[screen][role] = value
            end
          end
        end
      end
      attribute.screens = screens
      attribute.save!
    end

  end

end
