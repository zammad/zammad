# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class LastOwnerUpdate2 < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # reset assignment_timeout to prevent unwanted things happen
    Group.all.each do |group|
      group.assignment_timeout = nil
      group.save!
    end

    # check if column already exists
    if !ActiveRecord::Base.connection.column_exists?(:tickets, :last_owner_update_at)
      add_column :tickets, :last_owner_update_at, :timestamp, limit: 3, null: true
      add_index :tickets, [:last_owner_update_at]
      Ticket.reset_column_information
    end

    Scheduler.create_if_not_exists(
      name:          'Process auto unassign tickets',
      method:        'Ticket.process_auto_unassign',
      period:        10.minutes,
      prio:          1,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Cache.clear
  end

end
