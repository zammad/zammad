# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module TriggerWebhookJob::CustomPayload::PreDefined
  WEBHOOK_PREDEFINED_CLASS_PREFIX = 'Webhook::PreDefined::'.freeze

  def self.generate(type, values)
    return nil if values.blank?

    pre_defined_webhook = "#{WEBHOOK_PREDEFINED_CLASS_PREFIX}#{type}".constantize.new

    pre_defined_webhook_track = Struct.new('PreDefinedWebhook', *pre_defined_webhook.field_names)
    pre_defined_webhook_track.new(*values.values_at(*pre_defined_webhook_track.members))
  end

  def self.payload(type)
    pre_defined_webhook = "#{WEBHOOK_PREDEFINED_CLASS_PREFIX}#{type}".constantize.new

    JSON.pretty_generate(pre_defined_webhook.custom_payload)
  end
end
