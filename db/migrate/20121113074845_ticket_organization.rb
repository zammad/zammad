class TicketOrganization < ActiveRecord::Migration
  def up
    add_column :tickets, :organization_id, :integer, :null => true
  end

  def down
  end
end
