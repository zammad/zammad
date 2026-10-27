# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::SetFixedTo < CoreWorkflow::Result::BaseOption
  def run
    @result_object.result[:restrict_values][field] = if restriction_set?
                                                       filtered_restrict_values
                                                     else
                                                       config_value
                                                     end
    remove_excluded_param_values
    mark_restricted
    true
  end

  def config_value
    @config_value ||= begin
      result = Array.wrap(@perform_config['set_fixed_to'])
      result |= saved_value
      result
    end
  end

  def restriction_set?
    @result_object.result[:restrict_values][field]
  end

  def filtered_restrict_values
    restrict_values.reject { |v| config_value.exclude?(v) }
  end
end
