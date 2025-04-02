# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class DropSessionsJobsScheduler < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.where(method: 'Sessions.jobs').destroy_all
  end
end
