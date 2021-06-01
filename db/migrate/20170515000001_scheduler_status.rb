# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SchedulerStatus < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :schedulers do |t|
      t.string :error_message, null: true
      t.string :status, null: true
    end
  end
end
