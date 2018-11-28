# Copyright (C) 2018 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::CommunicateSignal < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    # if sender is customer, do not communicate
    return true if !record.sender_id

    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return true if sender.nil?
    return true if sender.name == 'Customer'

    # only apply on signal messages
    return true if !record.type_id

    type = Ticket::Article::Type.lookup(id: record.type_id)
    return true if type.name !~ /\Asignal/i

    Delayed::Job.enqueue(Observer::Ticket::Article::CommunicateSignal::BackgroundJob.new(record.id))
  end

end
