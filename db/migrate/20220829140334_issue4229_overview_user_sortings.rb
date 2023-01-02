# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4229OverviewUserSortings < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    create_table :user_overview_sortings do |t|
      t.column :user_id, :integer, null: false
      t.column :overview_id, :integer, null: false
      t.column :prio, :integer, null: false
      t.integer :updated_by_id, null: false
      t.integer :created_by_id, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :user_overview_sortings, :user_id
    add_index :user_overview_sortings, :overview_id
    add_foreign_key :user_overview_sortings, :users, column: :created_by_id
    add_foreign_key :user_overview_sortings, :users, column: :updated_by_id
    add_foreign_key :user_overview_sortings, :users, column: :user_id

    Permission.create_if_not_exists(
      name:         'user_preferences.overview_sorting',
      note:         'Change %s',
      preferences:  {
        translations: ['Order of Overviews'],
        required:     ['ticket.agent'],
      },
      allow_signup: true,
    )
  end
end
