class UpdateRecentViewedCreateObjectLookup < ActiveRecord::Migration
  def up

    if !ActiveRecord::Base.connection.table_exists? 'object_lookups'
      create_table :object_lookups do |t|
        t.column :name,         :string, :limit => 250,   :null => false
        t.timestamps
      end
      add_index :object_lookups, [:name],   :unique => true
    end
    RecentView.all.each {|entry|
      ro = RecentView::Object.find(entry.recent_view_object_id)
      lookup_id = ObjectLookup.by_name( ro.name )
      entry.update_attribute( :recent_view_object_id, lookup_id )
      entry.cache_delete
    }

    drop_table :recent_view_objects
    Cache.clear
  end

  def down
  end
end
