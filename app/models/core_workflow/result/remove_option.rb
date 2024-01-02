# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::RemoveOption < CoreWorkflow::Result::BaseOption
  def run
    update_restrict_values
    remove_excluded_param_values
    mark_restricted
    true
  end

  def update_restrict_values
    @result_object.result[:restrict_values][field] ||= Array(@result_object.payload['params'][field])
    @result_object.result[:restrict_values][field] -= Array(config_value)
  end

  def config_value
    result = Array(@perform_config['remove_option'])
    result -= saved_value
    result
  end
end
