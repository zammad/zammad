class PostmasterFilterCreate < ActiveRecord::Migration
  def up
    create_table :postmaster_filters do |t|
      t.column :name,           :string, limit: 250,  null: false
      t.column :channel,        :string, limit: 250,  null: false
      t.column :match,          :string, limit: 5000, null: false
      t.column :perform,        :string, limit: 5000, null: false
      t.column :active,         :boolean,                null: false, default: true
      t.column :note,           :string, limit: 250,  null: true
      t.column :updated_by_id,  :integer,                null: false
      t.column :created_by_id,  :integer,                null: false
      t.timestamps
    end
    add_index :postmaster_filters, [:channel]
  end

  def down
  end
end
