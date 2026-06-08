# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class DataPrivacyTaskJob < ApplicationJob
  include HasActiveJobLock

  def perform
    DataPrivacyTask.in_process.find_each(&:perform)
  end
end
