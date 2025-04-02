# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TriggerSchedulerLocalizationImprovements < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :triggers do |t|
      t.string :localization, limit: 20, null: true
      t.string :timezone,     limit: 250, null: true
    end
    Trigger.reset_column_information

    change_table :jobs do |t|
      t.string :localization, limit: 20, null: true
      t.string :timezone,     limit: 250, null: true
    end

    Job.reset_column_information
  end
end
