# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Issue2368AddIndicesToHistoriesAndTickets < ActiveRecord::Migration[5.1]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    add_index :histories, :related_o_id if !index_exists?(:histories, :related_o_id)
    add_index :histories, :related_history_object_id if !index_exists?(:histories, :related_history_object_id)
    add_index :histories, %i[o_id history_object_id related_o_id] if !index_exists?(:histories, %i[o_id history_object_id related_o_id])
    add_index :tickets, %i[group_id state_id] if !index_exists?(:tickets, %i[group_id state_id])
    add_index :tickets, %i[group_id state_id owner_id] if !index_exists?(:tickets, %i[group_id state_id owner_id])
  end
end
