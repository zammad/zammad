# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Adds certain (missing) meta data when creating articles.
# This module depends on AddsMetadataOriginById to run before it.
module Ticket::Article::AddsMetadataGeneral
  extend ActiveSupport::Concern

  included do
    before_create :ticket_article_add_metadata_general
  end

  private

  def ticket_article_add_metadata_general

    # return if we run import mode
    return true if Setting.get('import_mode')

    # only do fill of from if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return true if ApplicationHandleInfo.postmaster?

    # set from on all article types excluding email|twitter status|twitter direct-message|facebook feed post|facebook feed comment
    return true if type_id.blank?

    type = Ticket::Article::Type.lookup(id: type_id)

    # from will be set by channel backend
    return true if type.nil?
    return true if type.name == 'email'
    return true if type.name == 'twitter status'
    return true if type.name == 'twitter direct-message'
    return true if type.name == 'facebook feed post'
    return true if type.name == 'facebook feed comment'
    return true if type.name == 'sms'

    user_id = created_by_id

    if origin_by_id.present?

      # in case the customer is using origin_by_id, force it to current session user
      # and set sender to Customer
      if !created_by.permissions?('ticket.agent')
        self.origin_by_id = created_by_id
        self.sender_id = Ticket::Article::Sender.lookup(name: 'Customer').id
      end

      # in case origin_by is different than created_by, set sender to Customer
      # Customer in context of this conversation, not as a permission
      if origin_by != created_by_id
        self.sender_id = Ticket::Article::Sender.lookup(name: 'Customer').id
        user_id = origin_by_id
      end
    end
    return true if user_id.blank?

    user = User.find(user_id)
    is_customer = !TicketPolicy.new(user, ticket).agent_read_access?

    if (type.name == 'web' || type.name == 'phone') && is_customer
      self.from = "#{user.firstname} #{user.lastname} <#{user.email}>"
      return
    end
    self.from = "#{user.firstname} #{user.lastname}"
  end
end
