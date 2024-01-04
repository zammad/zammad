# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track
  include Mixin::RequiredSubPaths

  def self.root?
    false
  end

  def self.klass
    raise 'not implemented'
  end

  def self.functions
    klass.constantize.attribute_names
  end

  def self.replacements(pre_defined_webhook_type:)
    return {} if !root?

    raise 'not implemented'
  end
end
