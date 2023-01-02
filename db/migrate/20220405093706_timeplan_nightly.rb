# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TimeplanNightly < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :schedulers, :timeplan, :string, limit: 2500, null: true
    Scheduler.reset_column_information

    Scheduler.find_by(name: 'Clean up cache.').update(
      period:   10.minutes,
      timeplan: {
        'days'    => {
          'Mon' => true,
          'Tue' => true,
          'Wed' => true,
          'Thu' => true,
          'Fri' => true,
          'Sat' => true,
          'Sun' => true
        },
        'hours'   => {
          '23' => true
        },
        'minutes' => {
          '0' => true
        }
      }
    )
  end
end
