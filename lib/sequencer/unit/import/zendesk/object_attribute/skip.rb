# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::Skip < Sequencer::Unit::Base

  uses :field_map, :model_class, :resource, :sanitized_name
  provides :action

  # Skip fields which already exists and not editable.
  def process
    attribute = object_attribute_for_name

    return if !attribute || attribute.editable

    field_map[model_class.name] ||= {}
    field_map[model_class.name][ resource['key'] ] = sanitized_name

    logger.info { "Skipping. Default field '#{attribute}' found for field '#{sanitized_name}'." }

    state.provide(:action, :skipped)
  end

  private

  def object_attribute_for_name
    ObjectManager::Attribute.get(
      object: model_class.name,
      name:   sanitized_name
    )
  end
end
