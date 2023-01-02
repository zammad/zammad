# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DataPrivacyTaskJob < ApplicationJob
  include HasActiveJobLock

  def perform
    DataPrivacyTask.where(state: 'in process').find_each(&:perform)
  end
end
