# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Backend
  def self.perform(...)
    new(...).perform
  end

  attr_accessor :perform_result, :result, :relation_fields, :object

  def initialize(perform_result:, result:, relation_fields:, object:)
    @perform_result  = perform_result
    @result          = result
    @relation_fields = relation_fields
    @object          = object
  end

  def perform
    raise NotImplementedError
  end
end
