# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::Config < TriggerWebhookJob::CustomPayload::Track
  class << self
    def root?
      true
    end

    def klass
      'Struct::Config'
    end

    def functions
      %w[
        fqdn
        http_type
        ticket_hook
      ].freeze
    end

    def replacements(pre_defined_webhook_type:)
      {
        config: functions,
      }
    end

    def generate(tracks, _data)
      settings = {}
      functions.each do |setting|
        settings[setting] = Setting.get(setting)
      end

      Struct.new('Config', *settings.keys) if !defined?(Struct::Config)

      tracks[:config] = Struct::Config.new(*settings.values)
    end
  end
end
