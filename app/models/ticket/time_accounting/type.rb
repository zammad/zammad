# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::TimeAccounting::Type < ApplicationModel
  include HasDefaultModelUserRelations

  include ChecksHtmlSanitized
  include HasCollectionUpdate

  collection_push_permission('ticket.agent')

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :note, length: { maximum: 250 }
  sanitized_html :note
end
