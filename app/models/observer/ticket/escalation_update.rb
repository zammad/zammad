# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::EscalationUpdate < ActiveRecord::Observer
  observe 'ticket'

  def after_create(record)
    _check(record)
  end

  def after_update(record)
    _check(record)
  end

  private

  def _check(record)

    # return if we run import mode
    return false if Setting.get('import_mode')

    return false if !record.saved_changes?

    record.escalation_calculation
  end
end
