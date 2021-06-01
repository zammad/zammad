# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Adds origin_by_id field (if missing) when creating articles.
module Ticket::Article::AddsMetadataOriginById
  extend ActiveSupport::Concern

  included do
    before_create :ticket_article_add_metadata_origin_by_id
  end

  private

  def ticket_article_add_metadata_origin_by_id

    # return if we run import mode
    return true if Setting.get('import_mode')

    # only do fill origin_by_id if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return true if ApplicationHandleInfo.postmaster?

    # check if origin_by_id exists
    return true if origin_by_id.present?
    return true if ticket.blank?
    return true if ticket.customer_id.blank?
    return true if sender_id.blank?
    return true if sender.name != 'Customer'

    type_name = type.name
    return true if type_name != 'phone' && type_name != 'note' && type_name != 'web'

    self.origin_by_id = ticket.customer_id
  end
end
