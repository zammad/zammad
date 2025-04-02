# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddChecklists < ActiveRecord::Migration[5.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_tables
    create_template_tables
    create_setting
    create_permission
  end

  def create_permission
    Permission.create_if_not_exists(
      name:        'admin.checklist',
      label:       'Checklists',
      description: 'Manage ticket checklists of your system.',
      preferences: { prio: 1465 }
    )
  end

  def create_setting
    Setting.create_if_not_exists(
      title:       'Checklists',
      name:        'checklist',
      area:        'Web::Base',
      description: 'Enable checklists.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'checklist',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.checklist'],
      },
      state:       true,
      frontend:    true
    )
  end

  def create_tables
    create_table :checklists do |t|
      t.string  :name,      limit: 250,     null: false
      t.boolean :active,    default: true,  null: false
      if Rails.application.config.db_column_array
        t.string :sorted_item_ids, null: false, array: true, default: []
      else
        t.json :sorted_item_ids, null: false
      end
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.references :ticket, null: true, foreign_key: true, index: { unique: true }
      t.timestamps limit: 3, null: false
    end

    create_table :checklist_items do |t|
      t.text    :text,          null: false
      t.boolean :checked,       null: false, default: false
      t.references :checklist,  null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.timestamps limit: 3, null: false
    end
  end

  def create_template_tables
    create_table :checklist_templates do |t|
      t.string  :name,      limit: 250,     null: false
      t.boolean :active,    default: true,  null: false
      if Rails.application.config.db_column_array
        t.string :sorted_item_ids, null: false, array: true, default: []
      else
        t.json :sorted_item_ids, null: false
      end
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.timestamps limit: 3, null: false
    end

    create_table :checklist_template_items do |t|
      t.text :text, null: false
      t.references :checklist_template, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.timestamps limit: 3, null: false
    end
  end
end
