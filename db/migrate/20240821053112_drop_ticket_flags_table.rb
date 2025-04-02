# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class DropTicketFlagsTable < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    drop_table :ticket_flags
  end
end
