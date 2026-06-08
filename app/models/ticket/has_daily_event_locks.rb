# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Ticket::HasDailyEventLocks
  extend ActiveSupport::Concern

  included do
    has_many :daily_event_locks, class_name: 'Ticket::DailyEventLock', dependent: :delete_all

    after_save :cleanup_daily_event_locks
  end

  def cleanup_daily_event_locks
    cleanup_daily_event_locks_escalation
    cleanup_daily_event_locks_pending_reminder
  end

  def cleanup_daily_event_locks_escalation
    return if !saved_change_to_escalation_at?

    daily_event_locks
      .where(lock_activator: %w[escalation escalation_warning])
      .delete_all
  end

  def cleanup_daily_event_locks_pending_reminder
    return if !saved_change_to_pending_time?

    daily_event_locks
      .where(lock_activator: 'reminder_reached')
      .delete_all
  end
end
