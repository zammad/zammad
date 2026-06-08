# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AITextTools < ActiveRecord::Migration[4.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ai_text_tools_create_table
    ai_text_tools_groups_create_table
    ai_assistance_text_tools_fixed_instructions_setting
  end

  private

  def ai_text_tools_create_table
    create_table :ai_text_tools do |t|
      t.string 'name', limit: 250, null: false, default: ''

      t.string 'instruction', limit: 1.megabyte, null: false, default: ''

      t.string 'note', limit: 250

      t.boolean 'active', default: true, null: false

      t.references :created_by, type: :integer, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, type: :integer, null: false, foreign_key: { to_table: :users }

      t.timestamps limit: 3, null: false

      t.index :name, unique: true
      t.index :active
    end
  end

  def ai_text_tools_groups_create_table
    create_table :ai_text_tools_groups, id: false do |t|
      t.references :text_tool, foreign_key: { to_table: :ai_text_tools }
      t.references :group
    end
    add_index :ai_text_tools_groups, [:text_tool_id]
    add_index :ai_text_tools_groups, [:group_id]
    add_foreign_key :ai_text_tools_groups, :groups
  end

  def ai_assistance_text_tools_fixed_instructions_setting
    Setting.create_if_not_exists(
      title:       'Writing Assistant Fixed Instructions',
      name:        'ai_assistance_text_tools_fixed_instructions',
      area:        'AI::Assistance',
      description: 'Defines the fixed instructions that guide the AI Writing Assistant on e.g. how to format its output.',
      options:     {},
      state:       'Format:
- Write in the same language as the input
- **Always format the output as simple HTML content only**, do not wrap it in code block markers
- Use basic tags: `<h1>`, `<h2>`, `<p>`, `<strong>`, `<em>`, `<ul>`, `<li>`
- **DO NOT include DOCTYPE, `<html>`, `<head>`, `<body>`, or any document structure tags**
- Output should be ready to insert directly into an existing HTML document',
      preferences: {
        authentication: true,
        permission:     ['admin.ai_assistance_text_tools'],
      },
      frontend:    true,
    )
  end
end
