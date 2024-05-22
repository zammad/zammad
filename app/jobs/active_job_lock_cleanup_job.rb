# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ActiveJobLockCleanupJob < ApplicationJob
  include HasActiveJobLock

  def perform(diff = 1.day)
    ::ActiveJobLock.where(created_at: ...diff.ago).destroy_all
  end
end
