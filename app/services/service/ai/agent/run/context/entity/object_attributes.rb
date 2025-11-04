# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Entity::ObjectAttributes
  attr_reader :object_attribute, :entity_value

  def initialize(object_attribute:, entity_value:)
    @object_attribute = object_attribute
    @entity_value = entity_value
  end

  def prepare
    raise 'not implemented'
  end

  def self.applicable?
    raise 'not implemented'
  end
end
