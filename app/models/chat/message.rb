# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Chat::Message < ApplicationModel
  include ChecksHtmlSanitized

  belongs_to :chat_session, class_name: 'Chat::Session'
  belongs_to :created_by, class_name: 'User', optional: true

  sanitized_html :content
end
