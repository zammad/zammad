class SignatureUpdate < ActiveRecord::Migration
  def up

    create_table :email_addresses do |t|
      t.column :realname,       :string, :limit => 250,  :null => false
      t.column :email,          :string, :limit => 250,  :null => false
      t.column :active,         :boolean,                :null => false, :default => true
      t.column :note,           :string, :limit => 250,  :null => true
      t.column :updated_by_id,  :integer,                :null => false
      t.column :created_by_id,  :integer,                :null => false
      t.timestamps
    end
    add_index :email_addresses, [:email], :unique => true

    add_column :groups, :email_address_id,          :integer, :null => true

  end

  def down
  end
end
