# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CreatePublicLinks < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_table
    add_index :public_links, [:link], unique: true
    add_foreign_key :public_links, :users, column: :created_by_id
    add_foreign_key :public_links, :users, column: :updated_by_id

    add_permission
  end

  private

  def add_table
    create_table :public_links do |t|
      t.string  :link, limit: 500,        null: false
      t.string  :title, limit: 200,       null: false
      t.string  :description, limit: 200, null: true

      if Rails.application.config.db_column_array
        t.string :screen, null: false, array: true
      else
        t.json :screen, null: false
      end

      t.boolean :new_tab,                 null: false, default: true
      t.integer :prio,                    null: false
      t.column  :updated_by_id, :integer, null: false
      t.column  :created_by_id, :integer, null: false
      t.timestamps limit: 3,              null: false
    end
  end

  def add_permission
    Permission.create_if_not_exists(
      name:        'admin.public_links',
      note:        'Manage %s',
      preferences: {
        translations: ['Public Links']
      },
    )
  end
end
