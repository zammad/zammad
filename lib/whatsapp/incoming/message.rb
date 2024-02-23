# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Whatsapp::Incoming::Message < Whatsapp::Client

  attr_reader :messages_api, :phone_number_id

  def initialize(access_token:, phone_number_id:)
    super(access_token:)

    @phone_number_id = phone_number_id
    @messages_api = WhatsappSdk::Api::Messages.new client
  end

  def mark_as_read(message_id:)
    response = messages_api.read_message(sender_id: phone_number_id.to_i, message_id:)

    handle_error(response:)

    true
  end
end
