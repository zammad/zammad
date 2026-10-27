# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::MatchNoModules < CoreWorkflow::Condition::Backend
  def match
    result = true
    value.each do |_current_value|
      condition_value.each do |current_condition_value|
        custom_module = CoreWorkflow::Custom.lookup(current_condition_value)&.new(condition_object: @condition_object, result_object: @result_object)
        next if !custom_module

        check = custom_module.send(:"#{@condition_object.check}_attribute_match?")
        next if !check

        result = false

        break
      end
    end
    result
  end
end
