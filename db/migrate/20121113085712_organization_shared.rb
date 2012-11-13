class OrganizationShared < ActiveRecord::Migration
  def up
    add_column :overviews, :organization_shared, :boolean, :null => false, :default => false
  end

  def down
  end
end
