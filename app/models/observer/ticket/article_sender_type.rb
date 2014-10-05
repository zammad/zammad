# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::ArticleSenderType < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # get article count
    count = Ticket::Article.where( :ticket_id => record.ticket_id ).count
    return if count > 1

    record.ticket.create_article_type_id = record.type_id
    record.ticket.create_article_sender_id = record.sender_id

    # save ticket
    record.ticket.save
  end
end
