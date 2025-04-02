# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Webhook::Message::Status::Sent < Whatsapp::Webhook::Message::Status
  private

  def article_timestamp_key
    :timestamp_sent
  end

  def update_ticket?
    true
  end

  def update_ticket_attributes
    preferences = @ticket.preferences
    preferences[:whatsapp][:timestamp_outgoing] = status[:timestamp]

    { preferences: }
  end
end
