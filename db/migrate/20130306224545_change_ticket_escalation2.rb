class ChangeTicketEscalation2 < ActiveRecord::Migration
  def up
    add_column :tickets, :escalation_time,  :timestamp,  :null => true
    add_index :tickets, [:escalation_time]
  end

  def down
  end
end
