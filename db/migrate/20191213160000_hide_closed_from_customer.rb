class HideClosedFromCustomer < ActiveRecord::Migration[5.1]
    def up
  
      return if !Setting.find_by(name: 'system_init_done')

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
              default:    Ticket::State.find_by(default_create: true).id,
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
              default:    Ticket::State.find_by(default_follow_up: true).id,
            },
          },
        },
        to_create:   false,
        to_migrate:  false,
        to_delete:   false,
        position:    40,
      )
    end
  end
