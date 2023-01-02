# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingUpdates3 < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    settings_update = [
      {
        name:        'idoit_integration',
        description: 'Defines if the i-doit (https://www.i-doit.org/) integration is enabled or not.',
      },
      {
        title:       'Microsoft 365 App Credentials',
        name:        'auth_microsoft_office365_credentials',
        description: 'Enables user authentication via Microsoft 365.',
      },
    ]

    settings_update.each do |setting|
      fetched_setting = Setting.find_by(name: setting[:name])
      next if !fetched_setting

      if setting[:title]
        # "Updating title of #{setting[:name]} to #{setting[:title]}"
        fetched_setting.title = setting[:title]
      end

      if setting[:description]
        # "Updating description of #{setting[:name]} to #{setting[:description]}"
        fetched_setting.description = setting[:description]
      end

      fetched_setting.save!
    end
  end
end
