# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Whatsapp::Webhook
  module Concerns::HasChannel
    private

    def find_channel!(callback_url_uuid)
      channel = Channel.where(area: 'WhatsApp::Business', active: true).find do |c|
        c.options['callback_url_uuid'].to_s == callback_url_uuid.to_s
      end
      raise Whatsapp::Webhook::NoChannelError if channel.nil?

      channel
    end
  end

  class NoChannelError < StandardError
    def initialize
      super(__('The WhatsApp webhook channel could not be found.'))
    end
  end
end
