# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Text < Whatsapp::Webhook::Message
  private

  def body
    message[:body]
  end

  def content_type
    'text/plain'
  end

  def type
    :text
  end
end
