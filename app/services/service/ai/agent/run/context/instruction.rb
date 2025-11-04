# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Instruction
  attr_reader :instruction_object_attributes, :placeholder_object_attributes, :type_enrichment_data

  def initialize(instruction_context:, placeholder_object_attributes: [], type_enrichment_data: {})
    @instruction_object_attributes = instruction_context['object_attributes']
    @placeholder_object_attributes = placeholder_object_attributes
    @type_enrichment_data = type_enrichment_data
  end

  def prepare
    result = {}

    if instruction_object_attributes.present?
      result[:object_attributes] = prepare_instruction_object_attributes
    end

    result
  end

  private

  def prepare_instruction_object_attributes
    prepared_object_attributes = {}

    instruction_object_attributes.each_key do |name|
      object_attribute = get_object_attribute(name)
      next if object_attribute.blank?

      field_class = determine_object_attribute_class(object_attribute)
      next if field_class.blank?

      prepared_context = field_class.new(
        object_attribute: object_attribute,
        filter_values:    instruction_object_attributes[name]
      ).prepare_for_instruction

      next if prepared_context.blank?

      prepared_object_attributes[object_attribute.name] = {
        label: object_attribute.display,
        items: prepared_context
      }
    end

    prepared_object_attributes
  end

  def get_object_attribute(name)
    ObjectManager::Attribute.get(
      object: 'Ticket',
      name:   object_attribute_name_lookup(name)
    )
  end

  def object_attribute_name_lookup(name)
    placeholder_name = name.sub('placeholder.', '')

    return name if placeholder_object_attributes.blank?
    return name if placeholder_object_attributes.exclude?(placeholder_name)

    type_enrichment_data[placeholder_name] || name
  end

  def determine_object_attribute_class(object_attribute)
    object_attribute_classes.find do |klass|
      klass.applicable?(object_attribute)
    end
  end

  def object_attribute_classes
    [
      Service::AI::Agent::Run::Context::Instruction::ObjectAttributes::Relation,
      Service::AI::Agent::Run::Context::Instruction::ObjectAttributes::Options,
    ]
  end
end
