# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Link::Type < ApplicationModel
  include ChecksHtmlSanitized

  validates :name, presence: true

  sanitized_html :note
end
