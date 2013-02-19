class ChangeTicketEscalation < ActiveRecord::Migration
  def up
    add_column :tickets, :first_response_in_min,      :integer,  :null => true
    add_column :tickets, :first_response_diff_in_min, :integer,  :null => true
    add_index :tickets, [:first_response_in_min]
    add_index :tickets, [:first_response_diff_in_min]

    add_column :tickets, :close_time_in_min,          :integer,  :null => true
    add_column :tickets, :close_time_diff_in_min,     :integer,  :null => true
    add_index :tickets, [:close_time_in_min]
    add_index :tickets, [:close_time_diff_in_min]
  end
  def down
  end
end
