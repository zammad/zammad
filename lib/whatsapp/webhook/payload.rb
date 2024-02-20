# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Whatsapp::Webhook::Payload
  class << self
    include Whatsapp::Webhook::Concerns::HasChannel

    def validate!(raw:, callback_url_uuid:, signature:)
      channel = find_channel!(callback_url_uuid)
      secret = channel.options[:app_secret]

      digest = OpenSSL::Digest.new('sha256')
      raise ValidationError if OpenSSL::HMAC.hexdigest(digest, secret, raw) != signature
    end

    def process(data:, callback_url_uuid:)
      channel = find_channel!(callback_url_uuid)

      data.deep_symbolize_keys!

      phone_number_id = data[:entry].first[:changes].first[:value][:metadata][:phone_number_id]
      raise ProcessableError, __('Mismatching phone number id.') if channel.options[:phone_number_id] != phone_number_id

      raise ProcessableError, __('Unsupported subscription type.') if subscription(data) != 'messages'

      return process_status_message(data: data, channel: channel) if status_message?(data)

      raise ProcessableError if error?(data)

      process_message(data: data, channel: channel)
    end

    private

    def process_message(data:, channel:)
      # Zammad allowed message types
      # - text
      # - media (image, video, audio, document, sticker)
      # - reaction

      type = data[:entry].first[:changes].first[:value][:messages].first[:type]
      klass = "Whatsapp::Webhook::Message::#{type.capitalize}"

      raise ProcessableError, __('Unsupported message type.') if Whatsapp::Webhook::Message.descendants.map(&:to_s).exclude?(klass)

      klass.constantize.new(data:, channel:).process
    end

    def process_status_message(data:, channel:)
      # Zammad allowed status message types
      # - sent
      # - delivered
      # - read
      # - failed (undelivered)
    end

    def subscription(data)
      data[:entry].first[:changes].first[:field]
    end

    def error?(data)
      data[:entry].first[:changes].first[:value][:messages].first.key?(:errors)
    end

    def status_message?(data)
      data[:entry].first[:changes].first[:value].key?(:statuses)
    end

  end

  class ValidationError < StandardError
    def initialize
      super(__('The WhatsApp webhook payload could not be validated.'))
    end
  end

  class ProcessableError < StandardError
    attr_reader :reason

    def initialize(reason = nil)
      @reason = reason
      super(__('The WhatsApp webhook payload could not be processed.'))
    end
  end
end
