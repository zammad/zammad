class Observer::Ticket::UserTicketCounter::BackgroundJob
  def initialize(customer_id, updated_by_id)
    @customer_id = customer_id
    @updated_by_id = updated_by_id
  end

  def perform

    # open ticket count
    tickets_open = 0
    tickets_closed = 0
    if @customer_id != 1
      state_open = Ticket::State.by_category(:open)
      tickets_open = Ticket.where(
        customer_id: @customer_id,
        state_id: state_open,
      ).count()

      # closed ticket count
      state_closed = Ticket::State.by_category(:closed)
      tickets_closed = Ticket.where(
        customer_id: @customer_id,
        state_id: state_closed,
      ).count()
    end

    # check if update is needed
    customer = User.lookup(id: @customer_id)
    return true if !customer
    need_update = false
    if customer[:preferences][:tickets_open] != tickets_open
      need_update = true
      customer[:preferences][:tickets_open] = tickets_open
    end
    if customer[:preferences][:tickets_closed] != tickets_closed
      need_update = true
      customer[:preferences][:tickets_closed] = tickets_closed
    end

    return true if !need_update
    customer.updated_by_id = @updated_by_id
    customer.save
  end
end
