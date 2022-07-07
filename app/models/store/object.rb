# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Store < ApplicationModel
  class Object < ApplicationModel
    include ChecksHtmlSanitized

    validates :name, presence: true

    validates :note, length: { maximum: 250 }
    sanitized_html :note
  end
end
