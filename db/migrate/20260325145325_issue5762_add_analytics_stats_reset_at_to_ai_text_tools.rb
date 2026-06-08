# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue5762AddAnalyticsStatsResetAtToAITextTools < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    add_column :ai_text_tools, :analytics_stats_reset_at, :timestamp, limit: 3, null: true

    add_index :ai_analytics_runs, %i[triggered_by_type triggered_by_id],
              name:          'index_ai_analytics_runs_on_triggered_by',
              if_not_exists: true

    add_index :ai_analytics_usages, %i[ai_analytics_run_id created_at],
              name: 'index_ai_analytics_usages_on_run_id_and_created_at'

    AI::TextTool.reset_column_information
  end
end
