class AddAutoAssignFlagToTickets < ActiveRecord::Migration[5.1]
  def change
    add_column :tickets, :auto_assign, :boolean, default: false
  end
end
