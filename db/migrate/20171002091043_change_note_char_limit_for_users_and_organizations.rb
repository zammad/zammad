class ChangeNoteCharLimitForUsersAndOrganizations < ActiveRecord::Migration[5.1]
  def up
    change_column :organizations, :note, :string, limit: 5000
    change_column :users, :note, :string, limit: 5000
  end

  def down
    change_column :organizations, :note, :string, limit: 250
    change_column :users, :note, :string, limit: 250
  end
end
