# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Link::Type < ApplicationModel
  include ChecksHtmlSanitized

  validates :name, presence: true

  validates :note, length: { maximum: 250 }
  sanitized_html :note
end
