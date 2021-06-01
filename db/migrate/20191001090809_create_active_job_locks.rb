# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CreateActiveJobLocks < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :active_job_locks do |t|
      t.string :lock_key
      t.string :active_job_id

      t.timestamps # rubocop:disable Zammad/ExistsDateTimePrecision
    end
    add_index :active_job_locks, :lock_key, unique: true
    add_index :active_job_locks, :active_job_id, unique: true
  end
end
