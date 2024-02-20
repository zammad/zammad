# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Text < Whatsapp::Webhook::Message
  private

  def body
    data[:entry].first[:changes].first[:value][:messages].first[:text][:body]
  end

  def content_type
    'text/plain'
  end
end
