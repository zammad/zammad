# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::ContainsNot < CoreWorkflow::Condition::Backend
  def match
    value.blank? || value.any? { |v| condition_value.exclude?(v) }.present?
  end
end
