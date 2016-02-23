class AddProcessEscalationTickets < ActiveRecord::Migration
  def up
    Scheduler.create_if_not_exists(
      name: 'Process escalation tickets',
      method: 'Ticket.process_escalation',
      period: 60 * 5,
      prio: 1,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
