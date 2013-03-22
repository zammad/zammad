class TicketEscalationUpdateTime < ActiveRecord::Migration
  def up
    add_column :tickets, :update_time_escal_date,     :timestamp, :null => true
    add_column :tickets, :updtate_time_sla_time,      :timestamp, :null => true
    add_column :tickets, :update_time_in_min,         :integer,   :null => true
    add_column :tickets, :update_time_diff_in_min,    :integer,   :null => true
    add_index :tickets, [:update_time_in_min]
    add_index :tickets, [:update_time_diff_in_min]
  end

  def down
  end
end
