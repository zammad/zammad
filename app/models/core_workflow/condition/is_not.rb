# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Condition::IsNot < CoreWorkflow::Condition::Backend
  def match
    return true if value.blank?

    result = false
    value.each do |current_value|
      next if condition_value.include?(current_value)

      result = true

      break
    end
    result
  end
end
