# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SchedulerUpdates2 < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    schedulers_update = [
      {
        name:   "Clean up 'Cti::Log'.",
        method: 'Cti::Log.cleanup',
      },
    ]

    schedulers_update.each do |scheduler|
      fetched_scheduler = Scheduler.find_by(method: scheduler[:method])
      next if !fetched_scheduler

      if scheduler[:name]
        # p "Updating name of #{scheduler[:name]} to #{scheduler[:name]}"
        fetched_scheduler.name = scheduler[:name]
      end

      fetched_scheduler.save!
    end
  end
end
