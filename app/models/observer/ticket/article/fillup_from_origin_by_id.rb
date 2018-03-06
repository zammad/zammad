# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::FillupFromOriginById < ActiveRecord::Observer
  observe 'ticket::_article'

  def before_create(record)

    # return if we run import mode
    return if Setting.get('import_mode')

    # only do fill origin_by_id if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return if ApplicationHandleInfo.postmaster?

    # check if origin_by_id exists
    return if record.origin_by_id.present?
    return if record.ticket.customer_id.blank?
    return if record.sender.name != 'Customer'
    type_name = record.type.name
    return if type_name != 'phone' && type_name != 'note' && type_name != 'web'

    record.origin_by_id = record.ticket.customer_id
  end
end
