class ChangeTicketState < ActiveRecord::Migration
  def up
    rename_column :ticket_states, :ticket_state_type_id, :state_type_id
  end

  def down
  end
end
