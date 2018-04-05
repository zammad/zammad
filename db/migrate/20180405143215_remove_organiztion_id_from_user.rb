class RemoveOrganiztionIdFromUser < ActiveRecord::Migration[5.1]
  def up
    remove_column :users, :organization_id
  end

  def down
    add_reference :users, :organization, index: true
  end
end
