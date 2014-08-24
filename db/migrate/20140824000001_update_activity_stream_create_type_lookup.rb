class UpdateActivityStreamCreateTypeLookup < ActiveRecord::Migration
  def up

    if !ActiveRecord::Base.connection.table_exists? 'type_lookups'
      create_table :type_lookups do |t|
        t.column :name,         :string, :limit => 250,   :null => false
        t.timestamps
      end
      add_index :type_lookups, [:name],   :unique => true
    end
    ActivityStream.all.each {|entry|
      ro = ActivityStream::Type.find(entry.activity_stream_type_id)
      lookup_id = TypeLookup.by_name( ro.name )
      entry.update_attribute( :activity_stream_type_id, lookup_id )
      entry.cache_delete
    }

    drop_table :activity_stream_types
    Cache.clear
  end

  def down
  end
end
