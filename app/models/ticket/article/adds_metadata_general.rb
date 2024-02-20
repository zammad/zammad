# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Adds certain (missing) meta data when creating articles.
# This module depends on AddsMetadataOriginById to run before it.
module Ticket::Article::AddsMetadataGeneral
  extend ActiveSupport::Concern

  TYPE_NO_METADATA = [
    'email',
    'twitter status',
    'twitter direct-message',
    'facebook feed post',
    'facebook feed comment',
    'sms',
    'whatsapp message',
  ].freeze

  included do
    before_create :ticket_article_add_metadata_general
  end

  private

  def ticket_article_add_metadata_general
    return if !neither_importing_nor_postmaster?

    return if !type_uses_metadata_general?

    metadata_general_process_origin_by

    return if author.blank?

    metadata_general_process_from
  end

  def type_uses_metadata_general?
    return if type_id.blank?

    type = Ticket::Article::Type.lookup(id: type_id)

    return if TYPE_NO_METADATA.include? type.name

    true
  end

  def metadata_general_process_origin_by
    return if origin_by_id.blank?

    # in case the customer is using origin_by_id, force it to current session user
    # and set sender to Customer
    if !created_by.permissions?('ticket.agent')
      self.origin_by_id = created_by_id
      self.sender = Ticket::Article::Sender.lookup(name: 'Customer')
    end

    # in case origin_by is different than created_by, set sender to Customer
    # Customer in context of this conversation, not as a permission
    return if origin_by == created_by_id

    self.sender = Ticket::Article::Sender.lookup(name: 'Customer')
  end

  def metadata_general_process_from
    type        = Ticket::Article::Type.lookup(id: type_id)
    is_customer = !author.permissions?('ticket.agent')

    self.from = if %w[web phone].include?(type.name) && is_customer
                  Channel::EmailBuild.recipient_line "#{author.firstname} #{author.lastname}", author.email
                else
                  "#{author.firstname} #{author.lastname}"
                end
  end
end
