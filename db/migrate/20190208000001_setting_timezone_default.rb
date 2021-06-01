# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingTimezoneDefault < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Timezone',
      name:        'timezone_default',
      area:        'System::Branding',
      description: 'Defines the system default timezone.',
      options:     {
        form: [
          {
            name: 'timezone_default',
          }
        ],
      },
      state:       '',
      preferences: {
        prio:       9,
        controller: 'SettingsAreaItemDefaultTimezone',
        permission: ['admin.system'],
      },
      frontend:    true
    )
  end
end
