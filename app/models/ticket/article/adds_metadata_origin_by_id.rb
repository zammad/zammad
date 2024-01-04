# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Adds origin_by_id field (if missing) when creating articles.
module Ticket::Article::AddsMetadataOriginById
  extend ActiveSupport::Concern

  included do
    before_create :ticket_article_add_metadata_origin_by_id
  end

  private

  def ticket_article_add_metadata_origin_by_id
    return if !neither_importing_nor_postmaster?

    return if origin_by_id.present?

    return if ticket&.customer_id.blank?
    return if !sender || sender.name != 'Customer'
    return if %w[phone note web].exclude? type.name

    return if metadata_origin_by_customer_and_creator_colleagues?

    self.origin_by_id = ticket.customer_id
  end

  def neither_importing_nor_postmaster?
    # return if we run import mode
    return if Setting.get('import_mode')

    # only do fill origin_by_id if article got created via application_server (e. g. not
    # if article and sender type is set via *.postmaster)
    return if ApplicationHandleInfo.postmaster?

    true
  end

  def metadata_origin_by_customer_and_creator_colleagues?
    created_by_organizations = created_by.all_organizations.where(shared: true)
    customer_organizations   = ticket.customer.all_organizations.where(shared: true)

    created_by_organizations.ids.intersect? customer_organizations.ids
  end
end
