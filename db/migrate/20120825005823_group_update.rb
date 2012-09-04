class GroupUpdate < ActiveRecord::Migration
  def up
    # t.references :signature,                    :null => true
    add_column :groups, :signature_id,          :integer, :null => true
    add_column :groups, :assignment_timeout,    :integer, :null => true
    add_column :groups, :follow_up_possible,    :string,  :limit => 100, :default => 'yes', :null => true
    add_column :groups, :follow_up_assignment,  :boolean, :default => 1

    create_table :signatures do |t|
      t.column :name,           :string, :limit => 100,  :null => false
      t.column :body,           :string, :limit => 5000, :null => true
      t.column :active,         :boolean,                :null => false, :default => true
      t.column :note,           :string, :limit => 250,  :null => true
      t.column :created_by_id,  :integer,                :null => false
      t.timestamps
    end
    add_index :signatures, [:name], :unique => true
  end

  def down
  end
end
