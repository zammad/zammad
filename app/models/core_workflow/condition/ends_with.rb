# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::EndsWith < CoreWorkflow::Condition::Backend
  def match
    value.present? && value.all? { |v| condition_value.all? { |cv| v.ends_with?(cv) } }
  end
end
