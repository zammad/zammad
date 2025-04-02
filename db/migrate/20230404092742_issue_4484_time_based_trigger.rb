# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Issue4484TimeBasedTrigger < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :triggers do |t|
      t.string :activator, limit: 50, null: false, default: 'action'
      t.string :execution_condition_mode, limit: 50, null: false, default: 'selective'
      t.index %i[active activator]
    end

    Trigger.reset_column_information

    Setting.create_if_not_exists(
      title:       'Defines transaction backend.',
      name:        '9200_time_based_trigger',
      area:        'Transaction::Backend::Async',
      description: 'Defines the transaction backend which executes time based triggers.',
      options:     {},
      state:       'Transaction::TimeBasedTrigger',
      frontend:    false
    )
  end
end
