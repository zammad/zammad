# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class RemoveOtrsDiffWorkerSchedulerEntry < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.find_by(method: 'Import::OTRS.diff_worker')&.destroy
  end
end
