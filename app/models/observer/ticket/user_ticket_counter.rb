# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::UserTicketCounter < ActiveRecord::Observer
  observe 'ticket'

  def after_create(record)
    user_ticket_counter_update(record)
  end
  def after_update(record)
    user_ticket_counter_update(record)
  end

  def user_ticket_counter_update(record)
    return if !record.customer_id

    # open ticket count
    ticket_state_open_ids = Cache.get( 'ticket::state_ids::open' )
    if !ticket_state_open_ids
      ticket_state_open_ids = self.state_ids( ['new','open', 'pending reminder', 'pending action'] )
      Cache.write( 'ticket::state_ids::open', ticket_state_open_ids, { :expires_in => 1.hour } )
    end
    tickets_open = Ticket.where(
      :customer_id     => record.customer_id,
      :ticket_state_id => ticket_state_open_ids,
    ).count()

    # closed ticket count
    ticket_state_closed_ids = Cache.get( 'ticket::state_ids::closed' )
    if !ticket_state_closed_ids
      ticket_state_closed_ids = self.state_ids( ['closed'] )
      Cache.write( 'ticket::state_ids::closed', ticket_state_closed_ids, { :expires_in => 1.hour } )
    end
    tickets_closed = Ticket.where(
      :customer_id     => record.customer_id,
      :ticket_state_id => ticket_state_closed_ids,
    ).count()

    # check if update is needed
    customer = User.lookup( :id => record.customer_id )
    need_update = false
    if customer[:preferences][:tickets_open] != tickets_open
      need_update = true
      customer[:preferences][:tickets_open]   = tickets_open
    end
    if customer[:preferences][:tickets_closed] != tickets_closed
      need_update = true
      customer[:preferences][:tickets_closed] = tickets_closed
    end
    if need_update
      customer.save
    end
  end

  def state_ids(ticket_state_types)
    ticket_state_types = Ticket::StateType.where(
        :name => ticket_state_types,
    )
    ticket_states = Ticket::State.where( :state_type_id => ticket_state_types )
    ticket_state_ids = []
    ticket_states.each {|ticket_state|
      ticket_state_ids.push ticket_state.id
    }
    ticket_state_ids
  end

end

