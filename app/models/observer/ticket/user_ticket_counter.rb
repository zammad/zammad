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

    ticket_state_list_open   = Ticket::State.where( :state_type_id => Ticket::StateType.where( :name => ['new','open', 'pending reminder', 'pending action']) )
    ticket_state_list_closed = Ticket::State.where( :state_type_id => Ticket::StateType.where( :name => ['closed'] ) )

    tickets_open   = Ticket.where( :customer_id => record.customer_id, :ticket_state_id => ticket_state_list_open ).count()
    tickets_closed = Ticket.where( :customer_id => record.customer_id, :ticket_state_id => ticket_state_list_closed ).count()

    customer = User.find( record.customer_id )
    customer[:preferences][:tickets_open]   = tickets_open
    customer[:preferences][:tickets_closed] = tickets_closed
    customer.save
  end
end