# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AddHistorySource < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    migrate_table
    migrate_time_trigger_history_entries
  end

  private

  def migrate_table
    change_table :histories do |t|
      t.references :sourceable, polymorphic: true, null: true
      t.string :sourceable_name, limit: 500
    end
    History.reset_column_information
  end

  def migrate_time_trigger_history_entries
    old_history_entries.in_batches.each_record do |elem|
      update_record(elem)
    end
  end

  def update_record(record)
    record.update_columns( # rubocop:disable Rails/SkipsModelValidations
      sourceable_type:           'Trigger',
      sourceable_id:             record.related_o_id,
      sourceable_name:           record.value_to,
      related_history_object_id: nil,
      related_o_id:              nil,
      value_to:                  nil
    )
    record.cache_delete
  end

  def old_history_entries
    History.where(
      history_type_id: History.type_lookup('time_trigger_performed').id,
    )
  end
end
