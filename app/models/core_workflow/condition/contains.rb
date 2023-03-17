# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::Contains < CoreWorkflow::Condition::Backend
  def match
    result = false
    value.each do |current_value|
      current_match = false
      condition_value.each do |current_condition_value|
        next if current_condition_value.exclude?(current_value)

        current_match = true

        break
      end

      next if !current_match

      result = true

      break
    end
    result
  end
end
