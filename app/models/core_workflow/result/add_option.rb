# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::AddOption < CoreWorkflow::Result::BaseOption
  def run
    @result_object.result[:restrict_values][field] |= Array(@perform_config['add_option'])
    true
  end
end
