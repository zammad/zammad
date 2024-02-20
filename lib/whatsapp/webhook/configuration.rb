# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Whatsapp::Webhook::Configuration
  class << self
    include Whatsapp::Webhook::Concerns::HasChannel

    def verify!(options:)
      raise VerificationError if options.blank?

      raise VerificationError if options[:'hub.mode'] != 'subscribe'
      raise VerificationError if options[:'hub.challenge'].to_i.zero?

      channel = find_channel!(options[:callback_url_uuid])
      raise VerificationError if channel.options[:verify_token] != options[:'hub.verify_token']

      options[:'hub.challenge']
    end
  end

  class VerificationError < StandardError
    def initialize
      super(__('The WhatsApp channel webhook configuration could not be verified.'))
    end
  end
end
