# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::CommunicateTwitter < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.lookup( :id => record.ticket_article_sender_id )
    return 1 if sender == nil
    return 1 if sender['name'] == 'Customer'

    # only apply on tweets
    type = Ticket::Article::Type.lookup( :id => record.ticket_article_type_id )
    return if type['name'] != 'twitter direct-message' && type['name'] != 'twitter status'

    a = Channel::Twitter2.new
    message = a.send(
      {
        :type        => type['name'],
        :to          => record.to,
        :body        => record.body,
        :in_reply_to => record.in_reply_to
      },
      #      Rails.application.config.channel_twitter
    )
    record.message_id = message.id
    record.save
  end
end
