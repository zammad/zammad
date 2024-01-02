# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::AfterAbsolute < CoreWorkflow::Condition::Backend
  def match
    value_times.present? && value_times.all? { |v| condition_times.all? { |cv| v > cv } }
  end
end
