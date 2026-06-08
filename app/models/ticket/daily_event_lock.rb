# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Ticket::DailyEventLock < ApplicationModel
  validates :lock_type,
            presence:  true,
            inclusion: { in: %w[notification trigger] }

  validates :lock_activator,
            presence:  true,
            inclusion: { in: %w[reminder_reached escalation escalation_warning] }

  validates :date,
            presence:   true,
            uniqueness: { scope: %i[lock_type lock_activator ticket_id related_object_type related_object_id] }

  belongs_to :ticket
  belongs_to :related_object, polymorphic: true, optional: true

  # This method creates a daily lock for the given context.
  # If a lock is successfully created, it returns true.
  # If a lock already exists for the same context, it returns false.
  # Due to an unique index, it will work across transactions too!
  #
  # @param lock_type [String] The type of the lock (e.g., 'notification', 'trigger').
  # @param lock_activator [String] The activator of the lock (e.g., 'reminder_reached', 'escalation', 'escalation_warning').
  # @param ticket [Ticket] The ticket associated with the lock.
  # @param related_object [ApplicationRecord] An optional related object associated with the lock, e.g. a trigger or user.
  def self.lock!(lock_type:, lock_activator:, ticket:, related_object: nil)
    date = Time.use_zone(Setting.get('timezone_default')) { Time.current.beginning_of_day }

    create!(
      date:,
      lock_type:,
      lock_activator:,
      ticket:,
      related_object:
    )

    true
  rescue ActiveRecord::RecordInvalid => e # handles error at ActiveRecord level
    return false if e.record.errors.of_kind? :date, :taken

    raise e
  rescue ActiveRecord::RecordNotUnique # handles error at Postgres level in case of a race condition
    false
  end

  # cleanup old locks
  def self.cleanup
    where(updated_at: ...1.week.ago).delete_all

    true
  end
end
