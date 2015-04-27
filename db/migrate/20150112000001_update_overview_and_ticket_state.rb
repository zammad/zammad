class UpdateOverviewAndTicketState < ActiveRecord::Migration
  def up

    # if we are on upgrade mode
    overview_role = Role.where( name: 'Agent' ).first
    add_column :ticket_states, :next_state_id,  :integer, null: true
    UserInfo.current_user_id = 1
    if overview_role
      Overview.create_or_update(
        name: 'My pending reached Tickets',
        link: 'my_pending_reached',
        prio: 1010,
        role_id: overview_role.id,
        condition: {
          'tickets.state_id'     => [3],
          'tickets.owner_id'     => 'current_user.id',
          'tickets.pending_time' => { 'direction' => 'before', 'count' => 1, 'area' => 'minute' },
        },
        order: {
          by: 'created_at',
          direction: 'ASC',
        },
        view: {
          d: [ 'title', 'customer', 'group', 'created_at' ],
          s: [ 'title', 'customer', 'group', 'created_at' ],
          m: [ 'number', 'title', 'customer', 'group', 'created_at' ],
          view_mode_default: 's',
        },
      )
      Ticket::State.create_or_update( id: 3, name: 'pending reminder', state_type_id: Ticket::StateType.where(name: 'pending reminder').first.id  )
      Ticket::State.create_or_update( id: 6, name: 'removed', state_type_id: Ticket::StateType.where(name: 'removed').first.id, active: false )
      Ticket::State.create_or_update( id: 7, name: 'pending close', state_type_id: Ticket::StateType.where(name: 'pending action').first.id  )

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
    end
  end

  def down
  end
end
