# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TaskbarCleanupJob < ApplicationJob
  LAST_CONTACT_THRESHOLD = 1.day

  def perform
    Taskbar
      .where(app: :mobile)
      .where('last_contact < ?', LAST_CONTACT_THRESHOLD.ago)
      .destroy_all
  end
end
