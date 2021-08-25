# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::RemoveOption < CoreWorkflow::Result::BaseOption
  def run
    @result_object.result[:restrict_values][field] ||= Array(@result_object.payload['params'][field])
    @result_object.result[:restrict_values][field] -= Array(@perform_config['remove_option'])
    remove_excluded_param_values
    true
  end
end
