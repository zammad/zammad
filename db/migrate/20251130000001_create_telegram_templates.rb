# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreateTelegramTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :telegram_templates do |t|
      t.string :name, null: false
      t.text :content, null: false
      t.text :note
      t.boolean :active, default: true, null: false
      t.json :keyboard_buttons, default: []
      t.string :parse_mode, default: 'Markdown'
      t.integer :updated_by_id
      t.integer :created_by_id
      t.timestamps null: false
    end

    add_index :telegram_templates, :name, unique: true
    add_index :telegram_templates, :active

    create_table :groups_telegram_templates, id: false do |t|
      t.references :telegram_template
      t.references :group
    end
  end
end
