# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ActiveJobLockCleanupJob < ApplicationJob
  include HasActiveJobLock

  def perform(diff = 1.day)
    ::ActiveJobLock.where('created_at < ?', Time.zone.now - diff).destroy_all
  end
end
