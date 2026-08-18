# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddMissingPerformanceIndexes < ActiveRecord::Migration[8.0]
  # Some of these indexes already exist on installations where the table was
  # created by its original feature migration, because `t.references` adds one
  # implicitly since Rails 5.0. Installations set up from the base migrations
  # never got them, hence `if_not_exists`.
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Cti::Log list views sort the whole table by created_at
    # (Cti::Log.reorder(created_at: :desc).limit) and filter by queue
    # (Cti::Log.where(queue: ...)); neither column was indexed.
    add_index :cti_logs, [:created_at], if_not_exists: true
    add_index :cti_logs, [:queue], if_not_exists: true

    # Tickets are filtered directly by organization_id (e.g. Ticket::Stats),
    # and update_escalation_at is the only SLA escalation timestamp without an
    # index while all of its siblings are indexed.
    add_index :tickets, [:organization_id], if_not_exists: true
    add_index :tickets, [:update_escalation_at], if_not_exists: true

    # Foreign keys backing Checklist#items and the ticket <-> checklist item
    # lookups (Checklist.where(items: { ticket: ... })); previously unindexed.
    add_index :checklist_items, [:checklist_id], if_not_exists: true
    add_index :checklist_items, [:ticket_id], if_not_exists: true

    # Notification bell listing:
    # OnlineNotification.where(user_id: ...).reorder(created_at: :desc).
    add_index :online_notifications, %i[user_id created_at], if_not_exists: true
  end
end
