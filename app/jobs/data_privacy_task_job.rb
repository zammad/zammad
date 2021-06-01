# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class DataPrivacyTaskJob < ApplicationJob
  include HasActiveJobLock

  def perform
    DataPrivacyTask.where(state: 'in process').find_each(&:perform)
  end
end
