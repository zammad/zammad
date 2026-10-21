# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Condition::Today < CoreWorkflow::Condition::Backend
  def match
    Time.use_zone(Setting.get('timezone_default')) do
      value_times.all?(&:today?)
    end
  end
end
