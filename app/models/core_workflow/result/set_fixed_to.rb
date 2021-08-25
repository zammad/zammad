# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::SetFixedTo < CoreWorkflow::Result::BaseOption
  def run
    @result_object.result[:restrict_values][field] = if restriction_set?
                                                       restrict_values
                                                     else
                                                       replace_values
                                                     end
    remove_excluded_param_values
    true
  end

  def restriction_set?
    @result_object.result[:restrict_values][field]
  end

  def restrict_values
    @result_object.result[:restrict_values][field].reject { |v| Array(@perform_config['set_fixed_to']).exclude?(v) }
  end

  def replace_values
    Array(@perform_config['set_fixed_to'])
  end
end
