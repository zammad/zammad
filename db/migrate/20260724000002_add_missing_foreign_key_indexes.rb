# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddMissingForeignKeyIndexes < ActiveRecord::Migration[8.0]
  # Foreign key columns that had a constraint but no backing index. Without an
  # index PostgreSQL does a sequential scan of the child table on every delete
  # of a referenced parent row (RI check), and joins/filters on the column are
  # unindexed too. Only low/moderate-write tables are covered here; hot tables
  # where the write cost outweighs the benefit are intentionally left out
  # (see the analysis in the accompanying change).
  #
  # Some of these indexes already exist on installations where the table was
  # created by its original feature migration, because `t.references` adds one
  # implicitly since Rails 5.0. Installations set up from the base migrations
  # never got them, hence `if_not_exists`.
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_index :ai_analytics_runs, [:locale_id], if_not_exists: true
    add_index :ai_analytics_runs, [:regeneration_of_id], if_not_exists: true
    add_index :ai_analytics_usages, [:user_id], if_not_exists: true
    add_index :ai_stored_results, [:ai_analytics_run_id], if_not_exists: true
    add_index :ai_stored_results, [:locale_id], if_not_exists: true
    add_index :channels, [:group_id], if_not_exists: true
    add_index :checklist_template_items, [:checklist_template_id], if_not_exists: true
    add_index :cti_caller_ids, [:user_id], if_not_exists: true
    add_index :groups, [:email_address_id], if_not_exists: true
    add_index :groups, [:signature_id], if_not_exists: true
    add_index :mentions, [:user_id], if_not_exists: true
    add_index :oauth_access_grants, [:application_id], if_not_exists: true
    add_index :oauth_access_tokens, [:application_id], if_not_exists: true
    add_index :recent_closes, [:user_id], if_not_exists: true
    add_index :tags, [:tag_item_id], if_not_exists: true
    add_index :ticket_daily_event_locks, [:ticket_id], if_not_exists: true
    add_index :ticket_shared_draft_starts, [:group_id], if_not_exists: true
    add_index :ticket_shared_draft_zooms, [:ticket_id], if_not_exists: true
    add_index :ticket_states, [:state_type_id], if_not_exists: true
    add_index :ticket_time_accountings, [:type_id], if_not_exists: true
    add_index :user_two_factor_preferences, [:user_id], if_not_exists: true
  end
end
