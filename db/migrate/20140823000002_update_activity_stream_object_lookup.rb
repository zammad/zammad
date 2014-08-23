class UpdateActivityStreamObjectLookup < ActiveRecord::Migration
  def up

    ActivityStream.all.each {|entry|
      ao = ActivityStream::Object.find(entry.activity_stream_object_id)
      lookup_id = ObjectLookup.by_name( ao.name )
      entry.update_attribute( :activity_stream_object_id, lookup_id )
      entry.cache_delete
    }

    drop_table :activity_stream_objects
  end

  def down
  end
end
