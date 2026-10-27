# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::AddOption < CoreWorkflow::Result::BaseOption
  def run
    @result_object.result[:restrict_values][field] = restrict_values | Array.wrap(@perform_config['add_option'])
    readd_excluded_param_values
    mark_restricted
    true
  end
end
