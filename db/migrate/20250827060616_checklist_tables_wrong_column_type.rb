# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTablesWrongColumnType < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_column(Checklist)
    migrate_column(ChecklistTemplate)

    Checklist.reset_column_information
    ChecklistTemplate.reset_column_information
  end

  private

  def migrate_column(model)
    table = model.table_name

    return if ActiveRecord::Base.connection.columns(table).find { |c| c.name == 'sorted_item_ids' }.type == :string

    add_column table, :sorted_item_ids_tmp, :string, null: false, array: true, default: []

    execute <<~SQL.squish
      UPDATE #{table}
      SET sorted_item_ids_tmp = ARRAY(
        SELECT jsonb_array_elements_text(sorted_item_ids::jsonb)
      );
    SQL

    remove_column table, :sorted_item_ids
    rename_column table, :sorted_item_ids_tmp, :sorted_item_ids # rubocop:disable Zammad/ExistsResetColumnInformation
  end
end
