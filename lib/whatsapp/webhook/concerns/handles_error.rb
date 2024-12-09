# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Whatsapp::Webhook
  module Concerns::HandlesError
    private

    def error
      raise NotImplementedError
    end

    def handle_error
      # https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes
      #
      # Log any error status to the Rails log. Update the channel status on
      # any unrecoverable error - errors that need action from an administator
      # and block the channel from sending or receiving messages.

      Rails.logger.error "WhatsApp channel (#{@channel.options[:callback_url_uuid]}) - failed message: #{error[:title]} (#{error[:code]})"

      return if recoverable_error?(error[:code])
      return message_sender_error if sender_error?(error[:code])

      @channel.update!(
        status_out:   'error',
        last_log_out: "#{error[:title]} (#{error[:code]})",
      )
    end

    def recoverable_error?(code)
      [
        130_472, # User's number is part of an experiment
        131_021, # Recipient cannot be sender
        131_026, # Message undeliverable
        131_047, # Re-engagement message
        131_052, # Media download error
        131_053, # Media upload error
      ].include?(code)
    end

    def sender_error?(code)
      [
        131_051, # Unsupported message type
      ].include?(code)
    end

    def message_sender_error
      body = Translation.translate(
        Setting.get('locale_default') || 'en-us',
        __("Apologies, we're unable to process this kind of message due to restrictions within WhatsApp Business.")
      )

      Whatsapp::Outgoing::Message::Text.new(
        access_token:     @channel.options[:access_token],
        phone_number_id:  @channel.options[:phone_number_id],
        recipient_number: @data[:entry].first[:changes].first[:value][:messages].first[:from]
      ).deliver(body:)
    end
  end
end
