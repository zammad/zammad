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

      recoverable_errors = [
        130_472, # User's number is part of an experiment'
        131_021, # Recipient cannot be sender'
        131_026, # Message undeliverable'
        131_047, # Re-engagement message
        131_052, # Media download error'
        131_053  # Media upload error'
      ]
      return if recoverable_errors.include?(error[:code])

      @channel.update!(
        status_out:   'error',
        last_log_out: "#{error[:title]} (#{error[:code]})",
      )
    end
  end
end
