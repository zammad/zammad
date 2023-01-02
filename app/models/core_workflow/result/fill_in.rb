# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::FillIn < CoreWorkflow::Result::Backend
  def run
    return if skip?

    @result_object.result[:fill_in][field]  = fill_in_value
    @result_object.payload['params'][field] = @result_object.result[:fill_in][field]
    set_rerun
    true
  end

  def skip?
    return true if fill_in_value.nil?
    return true if params_set?
    return true if fill_in_set?

    false
  end

  def fill_in_value
    @perform_config['fill_in']
  end

  def params_set?
    @result_object.payload['params'][field] && fill_in_value == @result_object.payload['params'][field]
  end

  def fill_in_set?
    @result_object.result[:fill_in][field] && fill_in_value == @result_object.result[:fill_in][field]
  end
end
