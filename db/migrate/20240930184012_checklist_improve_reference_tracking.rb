# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistImproveReferenceTracking < ActiveRecord::Migration[7.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_default_empty_strings
    add_indexes
    change_column_null :checklists, :ticket_id, false
  end

  private

  def add_default_empty_strings
    change_column_default :checklists,               :name, ''
    change_column_default :checklist_templates,      :name, ''

    # MySQL does not support default text on non-null text items
    return if ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2'

    change_column_default :checklist_items,          :text, ''
    change_column_default :checklist_template_items, :text, ''
  end

  def add_indexes
    add_index :checklist_items,     :checked
    add_index :checklist_templates, :active
  end
end
