# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class History::Object < ApplicationModel
  include ChecksHtmlSanitized

  validates :note, length: { maximum: 250 }
  sanitized_html :note
end
