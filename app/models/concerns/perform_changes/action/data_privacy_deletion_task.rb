# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PerformChanges::Action::DataPrivacyDeletionTask < PerformChanges::Action
  def self.phase
    :initial
  end

  def execute(...)
    DataPrivacyTask.create_with(
      created_by_id: 1,
      updated_by_id: 1
    ).find_or_create_by(
      deletable: record,
    )
  end
end
