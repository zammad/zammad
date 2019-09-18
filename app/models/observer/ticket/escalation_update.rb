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

    # we need to fetch the a new instance of the record
    # from the DB instead of using `record.reload`
    # because Ticket#reload clears the ActiveMode::Dirty state
    # state of the record instance which leads to empty
    # Ticket#saved_changes (etc.) results in other callbacks
    # later in the chain
    updated_ticket = Ticket.find_by(id: record.id)
    return true if !updated_ticket

    updated_ticket.escalation_calculation
  end
end
