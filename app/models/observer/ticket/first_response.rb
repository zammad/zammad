class Observer::Ticket::FirstResponse < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)
#    puts 'check first response'

    # return if we run import mode
    return if Setting.get('import_mode')

    # if article in internal
    return true if record.internal

    # if sender is not agent
    return true if record.ticket_article_sender.name != 'Agent'

    # if article is a message to customer
    return true if !record.ticket_article_type.communication

    # check if first_response is already set
    return true if record.ticket.first_response

    # set first_response
    record.ticket.first_response = Time.now

    # save ticket
    record.ticket.save
  end
end