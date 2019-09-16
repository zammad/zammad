# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::CommunicateTelegram < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    # if sender is customer, do not communicate
    return true if !record.sender_id

    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return true if sender.nil?
    return true if sender.name == 'Customer'

    # only apply on telegram messages
    return true if !record.type_id

    type = Ticket::Article::Type.lookup(id: record.type_id)
    return true if !type.name.match?(/\Atelegram/i)

    Delayed::Job.enqueue(Observer::Ticket::Article::CommunicateTelegram::BackgroundJob.new(record.id))
  end

end
