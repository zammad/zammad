# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Signature < ApplicationModel
  include HasDefaultModelUserRelations
  include HasRichText

  include ChecksHtmlSanitized
  include HasCollectionUpdate
  include HasAuditLogs

  has_many  :groups,  after_add: :cache_update, after_remove: :cache_update
  validates :name,    presence: true

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  has_rich_text :body
  attachments_cleanup!

  collection_push_permission('ticket.agent')
end
