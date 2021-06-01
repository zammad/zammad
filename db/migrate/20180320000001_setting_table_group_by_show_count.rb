# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingTableGroupByShowCount < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Open ticket indicator',
      name:        'ui_table_group_by_show_count',
      area:        'UI::Base',
      description: 'Total display of the number of objects in a grouping.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_table_group_by_show_count',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
