# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::Is < CoreWorkflow::Condition::Backend
  def match
    result = false
    value.each do |current_value|
      next if condition_value.exclude?(current_value)

      result = true

      break
    end
    result
  end
end
