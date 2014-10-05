class UpdateStorage2 < ActiveRecord::Migration
  def up
    create_table :store_provider_dbs do |t|
      t.column :data,     :binary,        :limit => 200.megabytes,  :null => true
      t.column :md5,      :string,        :limit => 60,             :null => false
      t.timestamps
    end
    add_index :store_provider_dbs, [:md5],   :unique => true

    add_column  :store_files, :provider,    :string,  :limit => 20, :null => true
    add_index   :store_files, [:provider]

    Store::File.all.each {|file|
      if file.data
        file.update_attribute( :provider, 'DB' )
        Store::Provider::DB.add( file.data, file.md5 )
      else
        file.update_attribute( :provider, 'File' )
        Store::Provider::File.add( file.data, file.md5 )
      end
    }

    remove_column :store_files, :data
  end

  def down
  end
end
