# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddAIAgentType < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_type_column
  end

  private

  def add_type_column
    add_column :ai_agents, :agent_type, :string, limit: 250

    AI::Agent.reset_column_information
  end
end
