# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Adds certain (missing) meta data when creating email articles.
module Ticket::Article::AddsMetadataEmail
  extend ActiveSupport::Concern

  included do
    before_create :ticket_article_add_metadata_email
  end

  private

  def ticket_article_add_metadata_email
    return if !neither_importing_nor_postmaster?
    return if !sender_needs_metadata?
    return if !type_needs_metadata?

    metadata_email_process_subject
    metadata_email_process_message_id
    metadata_email_process_email_address
    metadata_email_process_from
  end

  def sender_needs_metadata?
    return if !sender_id

    sender = Ticket::Article::Sender.lookup(id: sender_id)
    return if sender&.name == 'Customer'

    true
  end

  def type_needs_metadata?
    return if !type_id

    type = Ticket::Article::Type.lookup(id: type_id)
    return if type&.name != 'email'

    true
  end

  def metadata_email_process_subject
    self.subject = ticket.subject_clean subject.presence || ticket.title
  end

  def metadata_email_process_message_id
    # generate message id, force it in production, in test allow to set it for testing reasons
    if !message_id || Rails.env.production?
      fqdn = Setting.get('fqdn')
      self.message_id = "<#{DateTime.current.to_fs(:number)}.#{ticket_id}.#{SecureRandom.uuid}@#{fqdn}>"
    end

    # generate message_id_md5
    check_message_id_md5
  end

  def metadata_email_process_email_address
    # set sender
    email_address = ticket.group.email_address

    if !email_address
      raise "No email address found for group '#{ticket.group.fullname}' (#{ticket.group_id})"
    end

    # remember email address for background job
    preferences['email_address_id'] = email_address.id
  end

  def recipient_name(email_address)
    if created_by_id != 1
      case Setting.get('ticket_define_email_from')
      when 'AgentNameSystemAddressName'
        separator = Setting.get('ticket_define_email_from_separator')
        return "#{created_by.firstname} #{created_by.lastname} #{separator} #{email_address.name}"
      when 'AgentName'
        return "#{created_by.firstname} #{created_by.lastname}"
      end
    end

    email_address.name
  end

  def metadata_email_process_from
    email_address = ticket.group.email_address

    self.from = Channel::EmailBuild.recipient_line(recipient_name(email_address), email_address.email)
  end
end
