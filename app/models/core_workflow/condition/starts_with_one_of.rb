# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::StartsWithOneOf < CoreWorkflow::Condition::Backend
  def match
    value.present? && value.any? { |v| condition_value.any? { |cv| v.starts_with?(cv) } }
  end
end
