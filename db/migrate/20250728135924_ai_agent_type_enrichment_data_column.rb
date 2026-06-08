# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AIAgentTypeEnrichmentDataColumn < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :ai_agents, :type_enrichment_data, :jsonb, null: false, default: {}

    AI::Agent.reset_column_information
  end
end
