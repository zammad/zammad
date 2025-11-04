# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreateAIAnalyticsRunsAndUsages < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :ai_analytics_runs do |t|
      t.string :identifier, null: false
      t.string :version
      t.string :ai_service_name, null: false, index: true

      t.references :locale, null: true, foreign_key: { to_table: :locales }
      t.references :related_object, polymorphic: true, null: true
      t.references :triggered_by, polymorphic: true, null: true

      t.references :regeneration_of, null: true, foreign_key: { to_table: :ai_analytics_runs }

      t.jsonb :content, null: false, default: {}
      t.jsonb :payload, null: false, default: {}
      t.jsonb :context, null: false, default: {}
      t.jsonb :error,   null: false, default: {}

      t.timestamps limit: 3
    end

    change_table :ai_stored_results do |t|
      t.references :ai_analytics_run, null: true, foreign_key: { to_table: :ai_analytics_runs }
    end

    AI::StoredResult.reset_column_information

    create_table :ai_analytics_usages do |t|
      t.references :ai_analytics_run, null: false, foreign_key: { to_table: :ai_analytics_runs }
      t.references :user, null: false, foreign_key: { to_table: :users }, type: :integer

      t.boolean :rating, null: true, default: nil # rubocop:disable Rails/ThreeStateBooleanColumn
      t.text :comment, null: true, default: nil

      t.jsonb :context, null: false, default: {}

      t.timestamps limit: 3

      t.index %i[ai_analytics_run_id user_id], unique: true
    end

    AI::StoredResult.delete_all
  end
end
