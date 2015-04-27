class TextModuleCreate < ActiveRecord::Migration
  def up
    create_table :text_modules do |t|
      t.references :user,                                       null: true
      t.column :name,                 :string,  limit: 250,  null: false
      t.column :keywords,             :string,  limit: 500,  null: true
      t.column :content,              :string,  limit: 5000, null: false
      t.column :note,                 :string,  limit: 250,  null: true
      t.column :active,               :boolean,                 null: false, default: true
      t.column :updated_by_id,        :integer,                 null: false
      t.column :created_by_id,        :integer,                 null: false
      t.timestamps
    end
    add_index :text_modules, [:user_id]
    add_index :text_modules, [:name]

    create_table :text_modules_groups, id: false do |t|
      t.integer :text_module_id
      t.integer :group_id
    end
    add_index :text_modules_groups, [:text_module_id]
    add_index :text_modules_groups, [:group_id]
  end

  def down
    drop_table :text_modules_groups
    drop_table :text_modules
  end

end
