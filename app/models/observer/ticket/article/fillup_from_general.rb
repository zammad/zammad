# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::FillupFromGeneral < ActiveRecord::Observer
  observe 'ticket::_article'

  def before_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # only do fill of from if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return if ApplicationHandleInfo.current.split('.')[1] == 'postmaster'

    # if sender is customer, do not change anything
    sender = Ticket::Article::Sender.lookup(id: record.sender_id)
    return if sender.nil?
    return if sender['name'] == 'Customer'

    # set from if not given
    return if record.from

    user        = User.find(record.created_by_id)
    record.from = "#{user.firstname} #{user.lastname}"
  end
end
