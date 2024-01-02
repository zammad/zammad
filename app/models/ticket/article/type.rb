# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Ticket::Article::Type < ApplicationModel
  include HasDefaultModelUserRelations

  include ChecksHtmlSanitized
  include HasCollectionUpdate

  validates :name, presence: true

  validates :note, length: { maximum: 250 }
  sanitized_html :note
end
