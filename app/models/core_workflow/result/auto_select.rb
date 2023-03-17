# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::AutoSelect < CoreWorkflow::Result::Backend
  def run
    return true if params_set? && !too_many_values?
    return if params_set?
    return if too_many_values?

    @result_object.result[:select][field]   = last_value
    @result_object.payload['params'][field] = last_value
    set_rerun
    true
  end

  def last_value
    result = @result_object.result[:restrict_values][field].last
    return [result] if multiple?

    result
  end

  def params_set?
    @result_object.payload['params'][field] == last_value
  end

  def too_many_values?
    @result_object.result[:restrict_values][field].count { |v| v != '' } != 1
  end
end
