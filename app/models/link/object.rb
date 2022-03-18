# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Link::Object < ApplicationModel
  include ChecksHtmlSanitized

  validates :name, presence: true

  sanitized_html :note
end
