class Observer::Ticket::LastContact < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)
#    puts 'check last contact'

    # if article in internal
    return true if record.internal

    # if article is a message to customer
    return true if !record.ticket_article_type.communication

    # if sender is not customer
    if record.ticket_article_sender.name == 'Customer'

      # check if last communication is done by agent, else do not set last_contact_customer
      if record.ticket.last_contact_customer == nil ||
        record.ticket.last_contact_agent == nil ||
        record.ticket.last_contact_agent.to_i > record.ticket.last_contact_customer.to_i
        record.ticket.last_contact_customer = Time.now

        # set last_contact
        record.ticket.last_contact = Time.now

        # save ticket
        record.ticket.save
      end
    end

    # if sender is not agent
    if record.ticket_article_sender.name == 'Agent'

      # set last_contact_agent
      record.ticket.last_contact_agent = Time.now

      # set last_contact
      record.ticket.last_contact = Time.now

      # save ticket
      record.ticket.save
    end
  end
end  