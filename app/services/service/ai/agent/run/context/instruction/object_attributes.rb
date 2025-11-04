# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run::Context::Instruction::ObjectAttributes
  attr_reader :object_attribute, :filter_values

  def initialize(object_attribute:, filter_values: {})
    @object_attribute = object_attribute
    @filter_values = filter_values
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
end
