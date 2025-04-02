# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action::DataPrivacyDeletionTask < PerformChanges::Action
  def self.phase
    :initial
  end

  def execute(...)
    DataPrivacyTask.create(
      deletable:     record,
      created_by_id: 1,
      updated_by_id: 1
    )
  end
end
