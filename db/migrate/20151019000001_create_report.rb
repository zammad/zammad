class CreateReport < ActiveRecord::Migration
  def up
    create_table :report_profiles do |t|
      t.column :name,           :string, limit: 150,   null: true
      t.column :condition,      :string, limit: 6000,  null: true
      t.column :active,         :boolean,              null: false, default: true
      t.column :updated_by_id,  :integer,              null: false
      t.column :created_by_id,  :integer,              null: false
      t.timestamps                                     null: false
    end
    add_index :report_profiles, [:name], unique: true

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Report::Profile.create_if_not_exists(
      name: '-all-',
      condition: {},
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Role.create_if_not_exists(name: 'Report', created_by_id: 1, updated_by_id: 1)
  end

  def down
    drop_table :report_profiles
  end
end
