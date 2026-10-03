# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action::CloseTaskbars < PerformChanges::Action
  def self.phase
    :initial
  end

  def execute(_prepared_actions)
    record.close_taskbars!
  end
end
