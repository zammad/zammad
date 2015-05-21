require 'scheduler'
require 'ticket/state'
class ProcessPendingTickets < ActiveRecord::Migration
  def up

    # fix wrong next_state_id for state 'pending close'
    pending_close_state = Ticket::State.find_by(
      name: 'pending close',
    )
    closed_state = Ticket::State.find_by(
      name: 'closed',
    )
    pending_close_state.next_state_id = closed_state.id
    pending_close_state.save!

    # add Ticket.process_pending
    Scheduler.create_or_update(
      name: 'Process pending tickets',
      method: 'Ticket.process_pending',
      period: 60 * 15,
      prio: 1,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
