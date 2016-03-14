
class OverviewUserRelation < ActiveRecord::Migration
  def up
    create_table :overviews_users, id: false do |t|
      t.integer :overview_id
      t.integer :user_id
    end
    add_index :overviews_users, [:overview_id]
    add_index :overviews_users, [:user_id]
    remove_column :overviews, :user_id
  end

end
