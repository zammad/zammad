class UpdateTicketState < ActiveRecord::Migration
  def up
    add_column :ticket_states, :ignore_escalation, :boolean, null: false, default: false

    return if !Ticket::State.first
    Ticket::State.create_or_update( id: 3, name: 'pending reminder', state_type_id: Ticket::StateType.find_by(name: 'pending reminder').id, ignore_escalation: true )
    Ticket::State.create_or_update( id: 4, name: 'closed', state_type_id: Ticket::StateType.find_by(name: 'closed').id, ignore_escalation: true )
    Ticket::State.create_or_update( id: 5, name: 'merged', state_type_id: Ticket::StateType.find_by(name: 'merged').id, ignore_escalation: true )
    Ticket::State.create_or_update( id: 6, name: 'removed', state_type_id: Ticket::StateType.find_by(name: 'removed').id, active: false, ignore_escalation: true )
    Ticket::State.create_or_update( id: 7, name: 'pending close', state_type_id: Ticket::StateType.find_by(name: 'pending action').id, next_state_id: 4, ignore_escalation: true )

  end
end