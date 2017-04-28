# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::FillupFromOriginById < ActiveRecord::Observer
  observe 'ticket::_article'

  def before_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # only do fill of from if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return if ApplicationHandleInfo.current.split('.')[1] == 'postmaster'

    # check if origin_by_id exists
    return if record.origin_by_id.present?
    return if !record.ticket.customer_id
    return if record.sender.name != 'Customer'
    return if record.type.name != 'phone'

    record.origin_by_id = record.ticket.customer_id
    user                = User.find(record.origin_by_id)
    record.from         = "#{user.firstname} #{user.lastname} <#{user.email}>"
  end
end
