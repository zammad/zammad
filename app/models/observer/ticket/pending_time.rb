# Ensures pending time is always zero-seconds
class Observer::Ticket::PendingTime < ActiveRecord::Observer
  observe 'ticket'

  def before_create(record)
    _check(record)
  end

  def before_update(record)
    _check(record)
  end

  private

  def _check(record)
    return true if record.pending_time.blank?
    return true if !record.pending_time_changed?
    return true if record.pending_time.sec.zero?

    record.pending_time = record.pending_time.change sec: 0
  end
end
