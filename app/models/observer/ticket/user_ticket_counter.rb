# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::UserTicketCounter < ActiveRecord::Observer
  observe 'ticket'

  def after_create(record)
    user_ticket_counter_update(record)
  end
  def after_update(record)
    user_ticket_counter_update(record)
  end

  def user_ticket_counter_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    return if !record.customer_id

    # open ticket count
    state_open    = Ticket::State.by_category( 'open' )
    tickets_open  = Ticket.where(
      customer_id: record.customer_id,
      state_id: state_open,
    ).count()

    # closed ticket count
    state_closed    = Ticket::State.by_category( 'closed' )
    tickets_closed  = Ticket.where(
      customer_id: record.customer_id,
      state_id: state_closed,
    ).count()

    # check if update is needed
    customer = User.lookup( id: record.customer_id )
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

end

