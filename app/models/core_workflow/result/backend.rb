# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::Backend
  def initialize(result_object:, field:, perform_config:)
    @result_object  = result_object
    @field          = field
    @perform_config = perform_config
  end

  def field
    @field.sub(%r{.*\.}, '')
  end

  def set_rerun
    @result_object.rerun = true
  end

  def result(backend, field, value = nil)
    @result_object.run_backend_value(backend, field, value)
  end
end
