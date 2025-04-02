# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::Type::WhatsappMessage::Deliver < Service::Ticket::Article::Type::BaseDeliver
  private

  def channel_adapter
    'whatsapp'.freeze
  end

  def check_channel!
    super

    error!(message: "Recipient phone number is missing in ticket.preferences['whatsapp']['from']['phone_number'] for Ticket.find(#{ticket.id})") if !from_phone_number
  end

  def deliver_arguments
    {
      body:             article.body,
      attachment:       article.attachments&.first,
      recipient_number: from_phone_number,
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
    @from_phone_number ||= ticket.preferences.dig('whatsapp', 'from', 'phone_number')
  end
end
