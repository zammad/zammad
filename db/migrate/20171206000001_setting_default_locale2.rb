# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingDefaultLocale2 < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'locale_default')
    if setting
      setting.area = 'System::Branding'
      setting.preferences[:prio] = 8
      setting.save!
    end

    Setting.create_if_not_exists(
      title:       'Locale',
      name:        'locale_default',
      area:        'System::Branding',
      description: 'Defines the system default language.',
      options:     {
        form: [
          {
            name: 'locale_default',
          }
        ],
      },
      state:       'en-us',
      preferences: {
        prio:       8,
        controller: 'SettingsAreaItemDefaultLocale',
        permission: ['admin.system'],
      },
      frontend:    true
    )
  end

end
