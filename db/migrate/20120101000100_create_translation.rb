class CreateTranslation < ActiveRecord::Migration
  def up
    create_table :translations do |t|
      t.column :locale,               :string,  :limit => 10,   :null => false
      t.column :source,               :string,  :limit => 255,  :null => false
      t.column :target,               :string,  :limit => 255,  :null => false
      t.column :target_initial,       :string,  :limit => 255,  :null => false
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :translations, [:source]
    add_index :translations, [:locale]
  end

  def down
    drop_table :translations
  end
end
