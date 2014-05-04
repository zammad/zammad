class UpdateStorage3 < ActiveRecord::Migration
  def up

    add_column  :store_files, :sha,    :string,  :limit => 128, :null => true
    add_index   :store_files, [:sha],  :unique => true

    add_column  :store_provider_dbs, :sha,    :string,  :limit => 128, :null => true
    add_index   :store_provider_dbs, [:sha],  :unique => true

    Store::File.all.each {|file|
      next if file.sha
      sha = Digest::SHA256.hexdigest( file.content )
      file.update_attribute( :sha, sha )
    }

    Store::Provider::DB.all.each {|file|
      next if file.sha
      sha = Digest::SHA256.hexdigest( file.data )
      file.update_attribute( :sha, sha )
    }

    remove_column :store_files, :md5
    remove_column :store_provider_dbs, :md5
  end

  def down
  end
end
