# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::SetFixedTo < CoreWorkflow::Result::BaseOption
  def run
    @result_object.result[:restrict_values][field] = if restriction_set?
                                                       restrict_values
                                                     else
                                                       config_value
                                                     end
    remove_excluded_param_values
    true
  end

  def config_value
    result = Array(@perform_config['set_fixed_to'])
    result |= Array(saved_value)
    result
  end

  def restriction_set?
    @result_object.result[:restrict_values][field]
  end

  def restrict_values
    @result_object.result[:restrict_values][field].reject { |v| config_value.exclude?(v) }
  end
end
