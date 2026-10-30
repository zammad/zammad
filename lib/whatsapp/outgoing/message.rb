# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Outgoing::Message < Whatsapp::Client

  attr_reader :phone_number_id, :recipient_number, :recipient, :messages_api

  def initialize(access_token:, phone_number_id:, recipient_number: nil, recipient: nil)
    super(access_token:)

    @phone_number_id = phone_number_id
    @recipient_number = recipient_number
    @recipient = recipient
    @messages_api = WhatsappSdk::Api::Messages.new client
  end

  def deliver
    raise NotImplementedError
  end

  # The SDK sends `to` for phone numbers and falls back to `recipient` (BSUID) if no number is given.
  def recipient_params
    { recipient_number: recipient_number.presence&.to_i, recipient: recipient.presence }
  end

  def handle_response(response:)
    {
      id: response.messages.first.id,
    }
  end
end
