# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Adds certain (missing) meta data when creating email articles.
module Ticket::Article::AddsMetadataEmail
  extend ActiveSupport::Concern

  included do
    before_create :ticket_article_add_metadata_email
  end

  private

  def ticket_article_add_metadata_email

    # return if we run import mode
    return true if Setting.get('import_mode')

    # only do fill of email from if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return if ApplicationHandleInfo.postmaster?

    # if sender is customer, do not change anything
    return true if !sender_id

    sender = Ticket::Article::Sender.lookup(id: sender_id)
    return true if sender.nil?
    return true if sender.name == 'Customer'

    # set email attributes
    return true if !type_id

    type = Ticket::Article::Type.lookup(id: type_id)
    return true if type.nil?
    return true if type.name != 'email'

    # set subject if empty
    ticket = self.ticket
    if !subject || subject == ''
      self.subject = ticket.title
    end

    # clean subject
    self.subject = ticket.subject_clean(subject)

    # generate message id, force it in production, in test allow to set it for testing reasons
    if !message_id || Rails.env.production?
      fqdn = Setting.get('fqdn')
      self.message_id = "<#{DateTime.current.to_s(:number)}.#{ticket_id}.#{rand(999_999_999_999)}@#{fqdn}>"
    end

    # generate message_id_md5
    check_message_id_md5

    # set sender
    email_address = ticket.group.email_address
    if !email_address
      raise "No email address found for group '#{ticket.group.name}' (#{ticket.group_id})"
    end

    # remember email address for background job
    preferences['email_address_id'] = email_address.id

    # fill from
    if created_by_id != 1 && Setting.get('ticket_define_email_from') == 'AgentNameSystemAddressName'
      separator   = Setting.get('ticket_define_email_from_separator')
      sender      = User.find(created_by_id)
      realname    = "#{sender.firstname} #{sender.lastname} #{separator} #{email_address.realname}"
      self.from = Channel::EmailBuild.recipient_line(realname, email_address.email)
    elsif Setting.get('ticket_define_email_from') == 'AgentName'
      sender      = User.find(created_by_id)
      realname    = "#{sender.firstname} #{sender.lastname}"
      self.from = Channel::EmailBuild.recipient_line(realname, email_address.email)
    else
      self.from = Channel::EmailBuild.recipient_line(email_address.realname, email_address.email)
    end
    true
  end
end
