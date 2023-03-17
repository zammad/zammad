# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Custom::Backend
  def initialize(condition_object:, result_object:)
    @condition_object = condition_object
    @result_object    = result_object
  end

  def saved_attribute_match?
    false
  end

  def selected_attribute_match?
    false
  end

  def perform; end

  def object?(object)
    @condition_object.attributes.instance_of?(object)
  end

  def selected
    @condition_object.attribute_object.selected
  end

  def selected_only
    @condition_object.attribute_object.selected_only
  end

  def saved
    @condition_object.attribute_object.saved
  end

  def saved_only
    @condition_object.attribute_object.saved_only
  end

  def params
    @condition_object.payload['params']
  end

  def result(backend, field, value = nil)
    @result_object.run_backend_value(backend, field, value)
  end
end
