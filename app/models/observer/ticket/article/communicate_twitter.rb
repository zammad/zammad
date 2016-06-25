# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::CommunicateTwitter < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is customer, do not communication
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return if sender.nil?
    return if sender['name'] == 'Customer'

    # only apply on tweets
    type = Ticket::Article::Type.lookup(id: record.type_id)
    return if type['name'] !~ /\Atwitter/i

    Delayed::Job.enqueue(Observer::Ticket::Article::CommunicateTwitter::BackgroundJob.new(record.id))
  end

end
