# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Backend
  def self.perform(...)
    new(...).perform
  end

  attr_accessor :perform_result, :result, :relation_fields

  def initialize(perform_result:, result:, relation_fields:)
    @perform_result = perform_result
    @result = result
    @relation_fields = relation_fields
  end

  def perform
    raise NotImplementedError
  end
end
