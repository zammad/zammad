# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Outgoing::Message < Whatsapp::Client

  attr_reader :phone_number_id, :recipient_number, :messages_api

  def initialize(access_token:, phone_number_id:, recipient_number:)
    super(access_token:)

    @phone_number_id = phone_number_id
    @recipient_number = recipient_number
    @messages_api = WhatsappSdk::Api::Messages.new client
  end

  def deliver
    raise NotImplementedError
  end

  def handle_response(response:)
    {
      id: response.messages.first.id,
    }
  end
end
