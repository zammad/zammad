# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'signature_detection'

class Observer::Ticket::Article::SignatureDetection < ActiveRecord::Observer
  observe 'ticket::_article'

  def before_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # if sender is not customer, do not change anything
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return if !sender
    return if sender['name'] != 'Customer'

    # set email attributes
    type = Ticket::Article::Type.lookup(id: record.type_id)
    return if type['name'] != 'email'

    # add queue job to update current signature of user id
    Delayed::Job.enqueue(Observer::Ticket::Article::SignatureDetection::BackgroundJob.new(record.created_by_id))

    # user
    user = User.lookup(id: record.created_by_id)
    return if !user
    return if !user.preferences
    return if !user.preferences[:signature_detection]

    record.preferences[:signature_detection] = SignatureDetection.find_signature_line(user.preferences[:signature_detection], record.body)
  end
end
