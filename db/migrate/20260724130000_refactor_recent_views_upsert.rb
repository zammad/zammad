# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RefactorRecentViewsUpsert < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    deduplicate_recent_views

    # RecentView now upserts and orders by updated_at, so the created_at index
    # is no longer used - replace it with an updated_at one (matching RecentClose).
    remove_index :recent_views, :created_at, if_exists: true
    add_index :recent_views, :updated_at, order: { updated_at: :desc }

    # Enforce the upsert tuple so duplicates can no longer be created.
    add_index :recent_views, %i[o_id recent_view_object_id created_by_id],
              name:   'index_recent_views_on_object_and_user',
              unique: true
  end

  private

  # Collapse duplicates to a single row per (o_id, recent_view_object_id,
  # created_by_id), keeping the newest id and carrying over the latest view time.
  def deduplicate_recent_views
    execute(<<~SQL.squish)
      UPDATE recent_views
      SET updated_at = grouped.max_created_at
      FROM (
        SELECT o_id, recent_view_object_id, created_by_id,
               MAX(id) AS keep_id, MAX(created_at) AS max_created_at
        FROM recent_views
        GROUP BY o_id, recent_view_object_id, created_by_id
      ) grouped
      WHERE recent_views.id = grouped.keep_id
    SQL

    execute(<<~SQL.squish)
      DELETE FROM recent_views
      WHERE id NOT IN (
        SELECT MAX(id)
        FROM recent_views
        GROUP BY o_id, recent_view_object_id, created_by_id
      )
    SQL
  end
end
