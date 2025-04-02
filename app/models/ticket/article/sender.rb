# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::Article::Sender < ApplicationModel
  include HasDefaultModelUserRelations

  include ChecksHtmlSanitized
  include HasCollectionUpdate

  validates :name, presence: true

  validates :note, length: { maximum: 250 }
  sanitized_html :note
end
