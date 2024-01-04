# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::EndsWithOneOf < CoreWorkflow::Condition::Backend
  def match
    value.present? && value.any? { |v| condition_value.any? { |cv| v.ends_with?(cv) } }
  end
end
