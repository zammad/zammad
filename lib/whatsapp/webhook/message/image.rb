# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Image < Whatsapp::Webhook::Message::Media
  private

  def type
    :image
  end
end
