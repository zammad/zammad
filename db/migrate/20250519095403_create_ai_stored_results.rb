# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class CreateAIStoredResults < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :ai_stored_results, id: :integer do |t|
      t.string :identifier, null: false
      t.string :version

      t.jsonb :metadata, null: false, default: {}
      t.jsonb :content, null: false, default: {}

      t.references :locale, null: true, foreign_key: { to_table: :locales }, type: :integer
      t.references :related_object, polymorphic: true, null: true,
        index: { name: 'index_ai_stored_results_on_related_object' }, type: :integer

      t.timestamps limit: 3

      t.index %i[identifier locale_id related_object_id related_object_type],
              unique: true,
              name:   'index_ai_stored_results_on_identifier_and_other'
    end
  end
end
