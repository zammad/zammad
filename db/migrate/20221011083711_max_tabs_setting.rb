# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MaxTabsSetting < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Maximum number of allowed tasks before auto cleanup removes surplus tasks.',
      name:        'ui_task_mananger_max_task_count',
      area:        'UI::TaskManager::Task::MaxCount',
      description: 'Defines the maximum number of allowed task bar tasks before auto cleanup removes surplus tasks when creating new tasks.',
      options:     {},
      state:       30,
      preferences: {
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
