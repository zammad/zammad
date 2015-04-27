class CreateTemplate < ActiveRecord::Migration
  def up
    create_table :templates do |t|
      t.references :user,                                       null: true
      t.column :name,                 :string,  limit: 250,  null: false
      t.column :options,              :string,  limit: 2500, null: false
      t.column :updated_by_id,        :integer,                 null: false
      t.column :created_by_id,        :integer,                 null: false
      t.timestamps
    end
    add_index :templates, [:user_id]
    add_index :templates, [:name]

    create_table :templates_groups, id: false do |t|
      t.integer :template_id
      t.integer :group_id
    end
    add_index :templates_groups, [:template_id]
    add_index :templates_groups, [:group_id]
  end

  def down
    drop_table :templates_groups
    drop_table :templates
  end
end
