# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::ContainsAll < CoreWorkflow::Condition::Backend
  def match
    (value & condition_value).count == condition_value.count
  end
end
