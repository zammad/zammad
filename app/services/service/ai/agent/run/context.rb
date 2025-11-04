# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context
  attr_reader :entity_object, :instruction_context, :entity_context, :entity_article, :placeholder_object_attributes, :type_enrichment_data

  def initialize(entity_object:, instruction_context:, entity_context:, entity_article: nil, placeholder_object_attributes: [], type_enrichment_data: {})
    @entity_object = entity_object
    @instruction_context = instruction_context || {}
    @entity_context = entity_context || {}
    @entity_article = entity_article
    @placeholder_object_attributes = placeholder_object_attributes
    @type_enrichment_data = type_enrichment_data
  end

  def prepare_instructions
    instruction = Service::AI::Agent::Run::Context::Instruction.new(
      instruction_context:,
      placeholder_object_attributes:,
      type_enrichment_data:,
    )

    instruction.prepare
  end

  def prepare_entity
    entity = Service::AI::Agent::Run::Context::Entity.new(
      entity_object:,
      entity_context:,
      entity_article:,
    )

    entity.prepare
  end
end
