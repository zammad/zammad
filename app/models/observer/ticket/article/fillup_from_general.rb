# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::Article::FillupFromGeneral < ActiveRecord::Observer
  observe 'ticket::_article'

  def before_create(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    # only do fill of from if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return true if ApplicationHandleInfo.postmaster?

    # set from on all article types excluding email|twitter status|twitter direct-message|facebook feed post|facebook feed comment
    return true if record.type_id.blank?

    type = Ticket::Article::Type.lookup(id: record.type_id)

    # from will be set by channel backend
    return true if type.nil?
    return true if type.name == 'email'
    return true if type.name == 'twitter status'
    return true if type.name == 'twitter direct-message'
    return true if type.name == 'facebook feed post'
    return true if type.name == 'facebook feed comment'
    return true if type.name == 'sms'

    user_id = record.created_by_id

    if record.origin_by_id.present?

      # in case the customer is using origin_by_id, force it to current session user
      # and set sender to Customer
      if !record.created_by.permissions?('ticket.agent')
        record.origin_by_id = record.created_by_id
        record.sender_id = Ticket::Article::Sender.lookup(name: 'Customer').id
      end

      # in case origin_by_id is customer, force it to set sender to Customer
      if record.origin_by != record.created_by_id && !record.origin_by.permissions?('ticket.agent')
        record.sender_id = Ticket::Article::Sender.lookup(name: 'Customer').id
        user_id = record.origin_by_id
      end
    end
    return true if user_id.blank?

    user = User.find(user_id)
    if type.name == 'web' || type.name == 'phone'
      record.from = "#{user.firstname} #{user.lastname} <#{user.email}>"
      return
    end
    record.from = "#{user.firstname} #{user.lastname}"
  end
end
