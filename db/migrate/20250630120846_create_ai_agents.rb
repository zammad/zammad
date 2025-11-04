# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreateAIAgents < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :ai_agents do |t|
      t.string 'name', limit: 250, null: false, default: ''
      t.jsonb 'definition', null: false, default: {}
      t.jsonb 'action_definition', null: false, default: {}

      t.string 'note', limit: 250

      t.boolean 'active', default: true, null: false

      t.references :created_by, type: :integer, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, type: :integer, null: false, foreign_key: { to_table: :users }

      t.timestamps limit: 3, null: false

      t.index :name, unique: true
      t.index :active
    end
  end
end
