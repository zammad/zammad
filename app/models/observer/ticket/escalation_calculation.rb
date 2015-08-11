# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Ticket::EscalationCalculation < ActiveRecord::Observer
  observe 'ticket', 'ticket::_article'

  def after_create(record)

    # return if we run import mode
    return if Setting.get('import_mode') && !Setting.get('import_ignore_sla')

    # do not recalculation if first respons is already out
    if record.class.name == 'Ticket::Article'
      record.ticket.escalation_calculation
      return true
    end

    # update escalation
    return if record.callback_loop
    record.callback_loop = true
    record.escalation_calculation
    record.callback_loop = false
  end

  def after_update(record)

    # return if we run import mode
    return if Setting.get('import_mode') && !Setting.get('import_ignore_sla')

    # do not recalculation if first respons is already out
    if record.class.name == 'Ticket::Article'
      record.ticket.escalation_calculation
      return true
    end

    # update escalation
    return if record.callback_loop
    record.callback_loop = true
    record.escalation_calculation
    record.callback_loop = false
  end
end
