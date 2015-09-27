class UpdateTicketState < ActiveRecord::Migration
  def up
    add_column :ticket_states, :ignore_escalation, :boolean, null: false, default: false

  end
end
