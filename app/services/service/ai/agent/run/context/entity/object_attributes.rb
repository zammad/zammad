# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How a field of the ticket reads in an AI agent's ticket context: one class per kind of field in this directory, found
#   by its file; a field no class takes is given by its stored value.
class Service::AI::Agent::Run::Context::Entity::ObjectAttributes
  include Mixin::RequiredSubPaths

  attr_reader :object_attribute, :entity_value

  def self.for(object_attribute)
    (descendants - [self::Default]).find { |klass| klass.applicable?(object_attribute) } || self::Default
  end

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

  private

  # An AI agent acts for nobody: the field is read without a user's permissions.
  def type
    @type ||= Service::EntityAttribute::Type.unscoped(object_attribute)
  end
end
