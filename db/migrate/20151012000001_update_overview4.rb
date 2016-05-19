class UpdateOverview4 < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    UserInfo.current_user_id = 1
    overview_role = Role.where( name: 'Agent' ).first
    Overview.create_or_update(
      name: 'My assigned Tickets',
      link: 'my_assigned',
      prio: 1000,
      role_id: overview_role.id,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ 1, 2, 3, 7 ],
        },
        'ticket.owner_id' => {
          operator: 'is',
          value: 'current_user.id',
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group created_at),
        s: %w(title customer group created_at),
        m: %w(number title customer group created_at),
        view_mode_default: 's',
      },
    )

    Overview.create_or_update(
      name: 'My pending reached Tickets',
      link: 'my_pending_reached',
      prio: 1010,
      role_id: overview_role.id,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: 3,
        },
        'ticket.owner_id' => {
          operator: 'is',
          value: 'current_user.id',
        },
        'ticket.pending_time' => {
          operator: 'within next (relative)',
          value: 0,
          range: 'minute',
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group created_at),
        s: %w(title customer group created_at),
        m: %w(number title customer group created_at),
        view_mode_default: 's',
      },
    )

    Overview.create_or_update(
      name: 'Unassigned & Open Tickets',
      link: 'all_unassigned',
      prio: 1020,
      role_id: overview_role.id,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
        'ticket.owner_id' => {
          operator: 'is',
          value: 1,
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group created_at),
        s: %w(title customer group created_at),
        m: %w(number title customer group created_at),
        view_mode_default: 's',
      },
    )

    Overview.create_or_update(
      name: 'All Open Tickets',
      link: 'all_open',
      prio: 1030,
      role_id: overview_role.id,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [1, 2, 3],
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group state owner created_at),
        s: %w(title customer group state owner created_at),
        m: %w(number title customer group state owner created_at),
        view_mode_default: 's',
      },
    )

    Overview.create_or_update(
      name: 'All pending reached Tickets',
      link: 'all_pending_reached',
      prio: 1035,
      role_id: overview_role.id,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [3],
        },
        'ticket.pending_time' => {
          operator: 'within next (relative)',
          value: 0,
          range: 'minute',
        },
      },
      order: {
        by: 'created_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group owner created_at),
        s: %w(title customer group owner created_at),
        m: %w(number title customer group owner created_at),
        view_mode_default: 's',
      },
    )

    Overview.create_or_update(
      name: 'Escalated Tickets',
      link: 'all_escalated',
      prio: 1040,
      role_id: overview_role.id,
      condition: {
        'ticket.escalation_time' => {
          operator: 'within next (relative)',
          value: '10',
          range: 'minute',
        },
      },
      order: {
        by: 'escalation_time',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group owner escalation_time),
        s: %w(title customer group owner escalation_time),
        m: %w(number title customer group owner escalation_time),
        view_mode_default: 's',
      },
    )

    overview_role = Role.where( name: 'Customer' ).first
    Overview.create_or_update(
      name: 'My Tickets',
      link: 'my_tickets',
      prio: 1000,
      role_id: overview_role.id,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ 1, 2, 3, 4, 6, 7 ],
        },
        'ticket.customer_id' => {
          operator: 'is',
          value: 'current_user.id',
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title state created_at),
        m: %w(number title state created_at),
        view_mode_default: 's',
      },
    )
    Overview.create_or_update(
      name: 'My Organization Tickets',
      link: 'my_organization_tickets',
      prio: 1100,
      role_id: overview_role.id,
      organization_shared: true,
      condition: {
        'ticket.state_id' => {
          operator: 'is',
          value: [ 1, 2, 3, 4, 6, 7 ],
        },
        'ticket.organization_id' => {
          operator: 'is',
          value: 'current_user.organization_id',
        },
      },
      order: {
        by: 'created_at',
        direction: 'DESC',
      },
      view: {
        d: %w(title customer state created_at),
        s: %w(number title customer state created_at),
        m: %w(number title customer state created_at),
        view_mode_default: 's',
      },
    )

    ObjectManager::Attribute.add(
      force: true,
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
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 15,
    )

    ObjectManager::Attribute.add(
      force: true,
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
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 25,
    )

  end
end
