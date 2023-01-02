# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4262AdminTemplatePermission < ActiveRecord::Migration[6.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Permission.create_if_not_exists(
      name:        'admin.template',
      note:        'Manage %s',
      preferences: {
        translations: ['Templates']
      },
    )
  end
end
