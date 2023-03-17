# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::BaseOption < CoreWorkflow::Result::Backend
  def remove_excluded_param_values
    if multiple?
      remove_array
    elsif excluded_by_restrict_values?(@result_object.payload['params'][field])
      remove_string
    end
  end

  def skip?
    @result_object.payload['params'][field].blank?
  end

  def remove_array
    @result_object.payload['params'][field] = Array(@result_object.payload['params'][field]).reject do |v|
      excluded = excluded_by_restrict_values?(v)
      if excluded
        set_rerun
      end
      excluded
    end
  end

  def remove_string
    @result_object.payload['params'][field] = @result_object.result[:restrict_values][field]&.first
    set_rerun
  end

  def excluded_by_restrict_values?(value)
    @result_object.result[:restrict_values][field].exclude?(value.to_s)
  end
end
