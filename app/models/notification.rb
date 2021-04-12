# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Notification < ApplicationModel
  include ChecksHtmlSanitized

  sanitized_html :note
end
