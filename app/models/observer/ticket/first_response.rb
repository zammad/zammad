# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::FirstResponse < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)
    #    puts 'check first response'

    # return if we run import mode
    return if Setting.get('import_mode')

    # if article in internal
    return true if record.internal

    # if sender is not agent
    sender = Ticket::Article::Sender.lookup( :id => record.sender_id )
    type   = Ticket::Article::Type.lookup( :id => record.type_id )
    if sender.name != 'Agent' && type.name !~ /^phone/
      return true
    end

    # if article is a message to customer
    return true if !type.communication

    # check if first_response is already set
    return true if record.ticket.first_response

    # set first_response
    record.ticket.first_response = record.created_at

    # save ticket
    record.ticket.save
  end
end
