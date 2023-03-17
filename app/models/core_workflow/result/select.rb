# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::Select < CoreWorkflow::Result::Backend
  def run
    return if skip?

    @result_object.result[:select][field]   = select_value
    @result_object.payload['params'][field] = @result_object.result[:select][field]
    set_rerun
    true
  end

  def skip?
    return true if select_value.nil?
    return true if params_set?
    return true if select_set?

    false
  end

  def select_value
    @select_value ||= Array(@perform_config['select']).reject { |v| @result_object.result[:restrict_values][field].exclude?(v) }
    return @select_value if multiple?

    @select_value.first
  end

  def params_set?
    @result_object.payload['params'][field] && select_value == @result_object.payload['params'][field]
  end

  def select_set?
    @result_object.result[:select][field] && select_value == @result_object.result[:select][field]
  end
end
