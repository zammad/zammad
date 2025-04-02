# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::WithinNextRelative < CoreWorkflow::Condition::Backend
  def match
    value_times.all? { |v| condition_times.all? { |cv| v > Time.zone.now && v < cv } }
  end
end
