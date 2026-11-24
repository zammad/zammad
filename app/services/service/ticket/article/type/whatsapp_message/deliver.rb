# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::Type::WhatsappMessage::Deliver < Service::Ticket::Article::Type::BaseDeliver
  private

  def channel_adapter
    'whatsapp'.freeze
  end

  def check_channel!
    super

    error!(message: "Recipient is missing in ticket.preferences['whatsapp']['from'] (phone_number or user_id) for Ticket.find(#{ticket.id})") if !from_phone_number && !from_user_id
  end

  # A phone number keeps the previous behaviour, the BSUID is only used if none is known.
  def deliver_arguments
    {
      body:             article.body,
      attachment:       article.attachments&.first,
      recipient_number: from_phone_number,
      recipient:        from_phone_number ? nil : from_user_id,
      message_type:     message_type,
    }
  end

  def handle_deliver_result
    article.preferences['whatsapp'] = {
      message_id: result[:id],
    }
    article.message_id = result[:id]
  end

  def message_type
    media? ? 'media' : 'text'
  end

  def media?
    article.attachments&.present?
  end

  def from_phone_number
    @from_phone_number ||= ticket.preferences.dig('whatsapp', 'from', 'phone_number').presence
  end

  def from_user_id
    @from_user_id ||= ticket.preferences.dig('whatsapp', 'from', 'user_id').presence
  end
end
