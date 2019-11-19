class AddPendingReviewAndDelegatedTicketStates < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Ticket::StateType.create_if_not_exists(id: 8, name: 'pending review', created_by_id: 1, updated_by_id: 1)
    Ticket::StateType.create_if_not_exists(id: 9, name: 'delegated', created_by_id: 1, updated_by_id: 1)
    
    Ticket::State.create_if_not_exists(
      id:                8,
      name:              'pending review',
      state_type_id:     Ticket::StateType.find_by(name: 'pending review').id,
      ignore_escalation: true,
      created_by_id:     1,
      updated_by_id:     1,
    )
    Ticket::State.create_if_not_exists(
      id:                9,
      name:              'delegated',
      state_type_id:     Ticket::StateType.find_by(name: 'delegated').id,
      ignore_escalation: true,
      created_by_id:     1,
      updated_by_id:     1,
    )
    
  end
end
