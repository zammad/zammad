# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CleanupCtiLog < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Scheduler.create_if_not_exists(
      name:          'Cleanup Cti::Log',
      method:        'Cti::Log.cleanup',
      period:        1.month,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

end
