# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Options < Service::AI::Agent::Run::Context::Entity::ObjectAttributes
  def self.applicable?(object_attribute)
    object_attribute.data_option[:options].present?
  end

  def prepare
    return if entity_value.blank?

    options = object_attribute.data_option[:historical_options] || object_attribute.data_option[:options] || {}
    return if !options.key?(entity_value)

    label = options[entity_value]

    label = entity_value if tree_select?

    {
      value: entity_value,
      label: label
    }
  end

  private

  def tree_select?
    %w[tree_select multi_tree_select].include?(object_attribute.data_type)
  end
end
