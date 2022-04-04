# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Ticket::Article::Type < ApplicationModel
  include ChecksHtmlSanitized
  include HasCollectionUpdate

  validates :name, presence: true

  sanitized_html :note
end
