# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Status::Delivered < Whatsapp::Webhook::Message::Status
  private

  def article_timestamp_key
    :timestamp_delivered
  end
end
