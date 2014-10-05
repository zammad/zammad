# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::LastContact < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)
    #    puts 'check last contact'

    # if article in internal
    return true if record.internal

    # if article is a message to customer
    return true if !Ticket::Article::Type.lookup( :id => record.type_id ).communication

    # if sender is not customer
    sender = Ticket::Article::Sender.lookup( :id => record.sender_id )
    if sender.name == 'Customer'

      # check if last communication is done by agent, else do not set last_contact_customer
      if record.ticket.last_contact_customer == nil ||
        record.ticket.last_contact_agent == nil ||
        record.ticket.last_contact_agent.to_i > record.ticket.last_contact_customer.to_i
        record.ticket.last_contact_customer = record.created_at

        # set last_contact
        record.ticket.last_contact = record.created_at

        # save ticket
        record.ticket.save
      end
    end

    # if sender is not agent
    if sender.name == 'Agent'

      # set last_contact_agent
      record.ticket.last_contact_agent = record.created_at

      # set last_contact
      record.ticket.last_contact = record.created_at

      # save ticket
      record.ticket.save
    end
  end
end
