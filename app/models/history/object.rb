# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class History::Object < ApplicationModel
  include ChecksHtmlSanitized

  sanitized_html :note
end
