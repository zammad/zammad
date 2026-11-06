# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Options < Service::AI::Agent::Run::Context::Entity::ObjectAttributes
  def self.applicable?(object_attribute)
    object_attribute.data_option[:options].present? && object_attribute.data_option[:relation].blank?
  end

  def prepare
    return if entity_value != false && entity_value.blank?

    options = object_attribute.data_option[:historical_options] || object_attribute.data_option[:options] || {}
    return if !options.key?(value)

    {
      value: value,
      label: type.label(entity_value),
    }
  end

  private

  # boolean options are stored with string keys, the instruction lists them the same way
  def value
    @value ||= object_attribute.data_type == 'boolean' ? entity_value.to_s : entity_value
  end
end
