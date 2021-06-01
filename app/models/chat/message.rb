# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Chat::Message < ApplicationModel
  include ChecksHtmlSanitized

  sanitized_html :content
end
