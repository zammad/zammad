# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketAddAIAgentsWorking < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :tickets do |t|
      t.boolean :ai_agent_running, default: false, null: false
      t.index :ai_agent_running
    end

    Ticket.reset_column_information
  end
end
