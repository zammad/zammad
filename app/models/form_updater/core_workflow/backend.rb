# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Backend
  def self.perform(...)
    new(...).perform
  end

  attr_accessor :perform_result, :result, :relation_fields, :object
  attr_reader :field_types

  # @param field_types [FormUpdater::FieldTypes] the field layer's types of the form's fields
  def initialize(perform_result:, result:, relation_fields:, object:, field_types:)
    @perform_result  = perform_result
    @result          = result
    @relation_fields = relation_fields
    @object          = object
    @field_types     = field_types
  end

  def perform
    raise NotImplementedError
  end
end
