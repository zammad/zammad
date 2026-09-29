# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Which of the given objects have a translation into the locale queued or running: the lock of
# ContentTranslationJob lives exactly that long.
class Service::ContentTranslation::InProgress < Service::Base
  # A lock left behind by a worker that died is only cleaned up after a day. A running translation
  # is bound by the AI provider timeout of 300 seconds by default, so anything older is taken for
  # such a leftover. A queued one is touched only when its job starts, and may wait behind a whole
  # ticket translated in the background.
  MAX_AGE        = 10.minutes
  MAX_QUEUED_AGE = 1.hour

  attr_reader :objects, :target_locale

  # @param objects [Array<ApplicationModel>]
  # @param target_locale [String] e.g. "de-de"
  def initialize(objects:, target_locale:)
    @objects       = objects
    @target_locale = target_locale
  end

  # @return [Array<ApplicationModel>] in the order given
  def execute
    return [] if objects.empty?

    keys = objects.index_by { |object| ContentTranslationJob.lock_key_for(object, target_locale) }

    locked = ActiveJobLock
      .where(lock_key: keys.keys)
      .merge(running.or(queued))
      .pluck(:lock_key)
      .to_set

    keys.filter_map { |key, object| object if locked.include?(key) }
  end

  private

  def running
    ActiveJobLock.where(updated_at: MAX_AGE.ago..)
  end

  # See ActiveJobLock#perform_pending?
  def queued
    table = ActiveJobLock.arel_table

    ActiveJobLock.where(table[:created_at].eq(table[:updated_at])).where(created_at: MAX_QUEUED_AGE.ago..)
  end
end
