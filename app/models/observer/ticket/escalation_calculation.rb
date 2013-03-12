class Observer::Ticket::EscalationCalculation < ActiveRecord::Observer
  observe 'ticket', 'ticket::_article'

  def after_create(record)
  end

  def after_update(record)

    # return if we run import mode
    return if Setting.get('import_mode') && !Setting.get('import_igonre_sla')

    # prevent loops
    return if record[:escalation_calc]
    record[:escalation_calc] = true

    # do not recalculation if first respons is already out
    if record.class.name == 'Ticket::Article'
      return true if record.ticket.first_response
      record.ticket.escalation_calculation
      return true
    end

    # update escalation
    record.escalation_calculation
  end
end