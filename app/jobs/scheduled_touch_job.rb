# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ScheduledTouchJob < ApplicationJob
  include HasActiveJobLock

  # Moving a date updates the job that is already waiting for it instead of being dismissed — a
  #   record whose touch was rescheduled has to be touched at the *new* date, and only at it.
  EXISTING_ACTIVE_JOB_LOCK_BEHAVIOUR = :upsert_date

  # `scope` tells the touches of one record apart, so a record with several scheduled dates gets a
  #   job per date rather than only the first one: they share a record, not a schedule. A knowledge
  #   base answer that goes internal on one date and public on another is exactly that
  #   (CanBePublished#schedule_touch passes the column each date lives in).
  def lock_key
    # "ScheduledTouchJob/KnowledgeBase::Answer/42/published_at"
    [self.class.name, arguments[0], arguments[1], arguments[2]].compact.join('/')
  end

  def self.touch_at(object, date, scope: nil)
    set(wait_until: date).perform_later(object.class.to_s, object.id, scope)
  end

  # `scope` is only there to key the lock above, so nothing here reads it.
  def perform(klass_name, id, _scope = nil)
    klass_name.constantize.find_by(id: id)&.touch # rubocop:disable Rails/SkipsModelValidations
  end
end
