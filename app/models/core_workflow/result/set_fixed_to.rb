# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::SetFixedTo < CoreWorkflow::Result::BaseOption
  def run
    @result_object.result[:restrict_values][field] = if restriction_set?
                                                       restrict_values
                                                     else
                                                       config_value
                                                     end
    remove_excluded_param_values
    mark_restricted
    true
  end

  def config_value
    @config_value ||= begin
      result = Array(@perform_config['set_fixed_to'])
      result |= saved_value
      result
    end
  end

  def restriction_set?
    @result_object.result[:restrict_values][field]
  end

  def restrict_values
    @result_object.result[:restrict_values][field].reject { |v| config_value.exclude?(v) }
  end
end
