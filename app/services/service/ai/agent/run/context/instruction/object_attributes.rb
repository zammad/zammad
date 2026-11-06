# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# How a field's values read in an AI agent's instructions: one class per kind of field in this directory, found by its
#   file; a field no class takes is left out.
class Service::AI::Agent::Run::Context::Instruction::ObjectAttributes
  include Mixin::RequiredSubPaths

  attr_reader :object_attribute, :filter_values

  def self.for(object_attribute)
    descendants.find { |klass| klass.applicable?(object_attribute) }
  end

  # @param filter_values [Hash, nil] the admin's choice of values with their descriptions; empty for every value
  def initialize(object_attribute:, filter_values: {})
    @object_attribute = object_attribute
    @filter_values = filter_values.is_a?(Hash) ? filter_values : {}
  end

  def prepare_for_instruction
    raise 'not implemented'
  end

  def self.applicable?
    raise 'not implemented'
  end

  private

  def filter_keys
    @filter_keys ||= filter_values.keys
  end

  # An AI agent acts for nobody: every value of the field, without a user's permissions.
  def type
    @type ||= Service::EntityAttribute::Type.unscoped(object_attribute)
  end
end
