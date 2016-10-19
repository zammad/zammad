# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::CommunicateEmail < ActiveRecord::Observer
  observe 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # only do send email if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return if ApplicationHandleInfo.current.split('.')[1] == 'postmaster'

    # if sender is customer, do not communicate
    return if !record.sender_id
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return 1 if sender.nil?
    return 1 if sender['name'] == 'Customer'

    # only apply on emails
    return if !record.type_id
    type = Ticket::Article::Type.lookup(id: record.type_id)
    return if type['name'] != 'email'

    # send background job
    Delayed::Job.enqueue(Observer::Ticket::Article::CommunicateEmail::BackgroundJob.new(record.id))
  end
end
