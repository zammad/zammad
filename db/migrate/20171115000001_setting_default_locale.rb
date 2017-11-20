class SettingDefaultLocale < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title: 'Locale',
      name: 'locale_default',
      area: 'System::Base',
      description: 'Defines the system default language.',
      options: {
        form: [
          {
            name: 'locale_default',
          }
        ],
      },
      state: 'en-us',
      preferences: {
        controller: 'SettingsAreaItemDefaultLocale',
        permission: ['admin.system'],
      },
      frontend: true
    )
  end

end
