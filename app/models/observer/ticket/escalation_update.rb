# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::EscalationUpdate < ActiveRecord::Observer
  observe 'ticket'

  def after_commit(record)
    _check(record)
  end

  private

  def _check(record)

    # return if we run import mode
    return true if Setting.get('import_mode')

    return true if !Ticket.exists?(record.id)
    record.reload
    record.escalation_calculation
  end
end
