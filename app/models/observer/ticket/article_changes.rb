# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::ArticleChanges < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    article_count_update(record)

    first_response_update(record)

    sender_type_update(record)

    last_contact_update(record)

    # save ticket
    record.ticket.save
  end

  # get article count
  def article_count_update(record)
    record.ticket.article_count = record.ticket.articles.count
  end

  # set frist response
  def first_response_update(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if article in internal
    return true if record.internal

    # if sender is not agent
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    type   = Ticket::Article::Type.lookup(id: record.type_id)
    return true if sender.name != 'Agent'

    # if article is a message to customer
    return true if !type.communication

    # check if first_response is already set
    return true if record.ticket.first_response

    # set first_response
    record.ticket.first_response = record.created_at

    true
  end

  # set sender type
  def sender_type_update(record)

    # ignore if create channel is already set
    count = Ticket::Article.where(ticket_id: record.ticket_id).count
    return if count > 1

    record.ticket.create_article_type_id   = record.type_id
    record.ticket.create_article_sender_id = record.sender_id
  end

  # set last contact
  def last_contact_update(record)

    # if article in internal
    return true if record.internal

    # if article is a message to customer
    return true if !Ticket::Article::Type.lookup(id: record.type_id).communication

    # if sender is customer
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    if sender.name == 'Customer'

      # check if last communication is done by agent, else do not set last_contact_customer
      if record.ticket.last_contact_customer.nil? ||
         record.ticket.last_contact_agent.nil? ||
         record.ticket.last_contact_agent.to_i > record.ticket.last_contact_customer.to_i

        # set last_contact customer
        record.ticket.last_contact_customer = record.created_at

        # set last_contact
        record.ticket.last_contact = record.created_at

      end
      return true
    end

    # if sender is not agent
    return if sender.name != 'Agent'

    # set last_contact_agent
    record.ticket.last_contact_agent = record.created_at

    # set last_contact
    record.ticket.last_contact = record.created_at

    true
  end
end
