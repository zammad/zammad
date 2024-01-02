# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Webhook::PreDefined
  include Mixin::RequiredSubPaths

  def self.pre_defined_webhooks
    descendants.sort_by(&:name)
  end

  def self.pre_defined_webhook_definitions
    pre_defined_webhooks.map { |x| x.new.definition }
  end

  def definition
    {
      id:             self.class.name.demodulize,
      name:           name,
      custom_payload: generated_custom_payload,
      fields:         fields,
      field_names:    field_names,
    }
  end

  def name
    raise NotImplementedError
  end

  def custom_payload
    raise NotImplementedError
  end

  def fields
    []
  end

  def field_names
    fields.pluck(:name)
  end

  private

  def generated_custom_payload
    JSON.pretty_generate(custom_payload)
  end
end
