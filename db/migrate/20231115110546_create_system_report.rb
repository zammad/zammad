# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CreateSystemReport < ActiveRecord::Migration[7.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    setup_table
    setup_permissions
  end

  def setup_table
    create_table :system_reports do |t|
      t.text :data
      t.string :uuid, limit: 50, null: false

      t.integer :created_by_id, null: false
      t.timestamps limit: 3, null: false

    end
    add_index :system_reports, [:uuid], unique: true
  end

  def setup_permissions
    Permission.create_if_not_exists(
      name:        'admin.system_report',
      note:        'Manage %s',
      preferences: {
        translations: ['System Report']
      },
    )
  end
end
