class AddPendingReviewAndDelegatedTicketStates < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Ticket::StateType.create_if_not_exists(id: 8, name: 'pending review')
    Ticket::StateType.create_if_not_exists(id: 9, name: 'delegated')
    
    Ticket::State.create_if_not_exists(
      id:                8,
      name:              'pending review',
      state_type_id:     Ticket::StateType.find_by(name: 'pending review').id,
      ignore_escalation: true,
    )
    Ticket::State.create_if_not_exists(
      id:                9,
      name:              'delegated',
      state_type_id:     Ticket::StateType.find_by(name: 'delegated').id,
      ignore_escalation: true,
    )
    
  end
end
